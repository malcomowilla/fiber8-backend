


class HotspotIncidentCompensationService
  Result = Struct.new(:compensated_count, :sms_sent_count, :voucher_ids, keyword_init: true)

  def initialize(account, grace_duration)
    @account = account
    @grace_duration = grace_duration
  end

  def compensate(scope, notify: true, company_name: nil)
    compensated_ids = []

    deduped_scope(scope).find_each do |voucher|
      new_expiration_time = compensated_expiration_for(voucher)
      next unless new_expiration_time

      unless voucher.update(expiration: new_expiration_time, status: 'active')
        Rails.logger.error "HotspotIncidentCompensationService: failed to update voucher #{voucher.id}: #{voucher.errors.full_messages.join(', ')}"
        next
      end

      sync_to_router(voucher, new_expiration_time)
      compensated_ids << voucher.id
    end

    sms_sent = notify ? notify_customers(HotspotVoucher.where(id: compensated_ids), company_name) : 0

    Result.new(compensated_count: compensated_ids.size, sms_sent_count: sms_sent, voucher_ids: compensated_ids)
  end

  private

  def deduped_scope(scope)
    phoned_ids    = scope.where.not(phone: [nil, '']).group(:phone).maximum(:id).values
    phoneless_ids = scope.where(phone: [nil, '']).pluck(:id)
    HotspotVoucher.where(id: phoned_ids + phoneless_ids)
  end

  def compensated_expiration_for(voucher)
    current_expiration = voucher.expiration

    if voucher.status == 'active' && current_expiration.present?
      current_expiration + @grace_duration
    else
      Time.current + @grace_duration
    end
  end

  def router_uses_radius?
    setting = NasSetting.find_by(account_id: @account.id)
    setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
  end

  def real_time_mode?
    @account.hotspot_setting&.voucher_expiration == 'Real-time expiration'
  end

  def sync_to_router(voucher, expiration_time)
    if router_uses_radius?
      real_time_mode? ? sync_radius_expiration(voucher, expiration_time) : sync_radius_accumulated(voucher)
    elsif real_time_mode?
      sync_native_bare(voucher)
    end
    # native + accumulated: intentionally not synced — see class comment
  end

  def sync_radius_expiration(voucher, expiration_time)
    RadCheck.find_or_initialize_by(
      username: voucher.voucher,
      account_id: @account.id,
      radiusattribute: 'Expiration'
    ).update!(op: ':=', value: expiration_time.strftime("%d %b %Y %H:%M:%S"))
  rescue => e
    Rails.logger.error "HotspotIncidentCompensationService: RadCheck Expiration update failed for #{voucher.voucher}: #{e.message}"
  end

  def sync_radius_accumulated(voucher)
    record = RadCheck.find_or_initialize_by(
      username: voucher.voucher,
      account_id: @account.id,
      radiusattribute: 'Max-All-Session'
    )
    current_seconds = record.value.to_i
    record.update!(op: ':=', value: (current_seconds + @grace_duration.to_i).to_s)
  rescue => e
    Rails.logger.error "HotspotIncidentCompensationService: RadCheck Max-All-Session update failed for #{voucher.voucher}: #{e.message}"
  end

  def sync_native_bare(voucher)
    package = HotspotPackage.find_by(name: voucher.package, account_id: @account.id)
    return unless package

    nas = NasRouter.find_by(name: package.nas_router, account_id: @account.id)
    return unless nas

    RestClient::Request.execute(
      method: :put,
      url: "http://#{nas.ip_address}/rest/ip/hotspot/user",
      user: nas.username.to_s, password: nas.password.to_s,
      payload: { name: voucher.voucher, password: voucher.voucher, profile: package.name }.to_json,
      headers: { content_type: :json },
      timeout: 10, open_timeout: 5
    )
    voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)
  rescue => e
    Rails.logger.error "HotspotIncidentCompensationService: native sync failed for #{voucher.voucher}: #{e.message}"
    voucher.update(sync_status: 'failed', sync_error: e.message)
  end

  def notify_customers(vouchers, company_name)
    sent = 0
    provider = @account.sms_provider_setting&.sms_provider

    vouchers.find_each do |voucher|
      next if voucher.phone.blank?

      begin
        message = compensation_message(voucher.reload, company_name)
        case provider
        when 'SMS leopard' then send_sms_leopard(voucher.phone, message)
        when 'TextSms'     then send_textsms(voucher.phone, message)
        when 'Talk Sasa'   then send_talksasa(voucher.phone, message)
        else
          next
        end
        sent += 1
      rescue => e
        Rails.logger.error "HotspotIncidentCompensationService: SMS failed for #{voucher.phone}: #{e.message}"
      end
    end

    sent
  end

  def compensation_message(voucher, company_name)
    template = HotspotSmsTemplate.active_for(@account.id, 'incident_compensation')
    data = {
      customer_phone: voucher.phone,
      voucher_code: voucher.voucher,
      plan_name: voucher.package,
      validity: voucher.expiration&.strftime("%B %d, %Y at %I:%M %p") || "your next login",
      company_name: company_name || @account.company_setting&.company_name
    }
    return template.render(data) if template

    "We're sorry for today's service interruption. Your voucher #{voucher.voucher} has been " \
      "extended and is now valid until #{data[:validity]}. Thank you for your patience. (FROM: #{data[:company_name]})"
  end

  def send_sms_leopard(phone, message)
    setting = SmsSetting.find_by(sms_provider: 'SMS leopard')
    uri = URI("https://api.smsleopard.com/v1/sms/send")
    uri.query = URI.encode_www_form(
      username: setting&.api_key, password: setting&.api_secret,
      message: message, destination: phone, source: "SMS_TEST"
    )
    Net::HTTP.get_response(uri)
  end

  def send_textsms(phone, message)
    setting = SmsSetting.find_by(sms_provider: 'TextSms')
    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    uri.query = URI.encode_www_form(
      apikey: setting&.api_key, message: message, mobile: phone,
      partnerID: setting&.partnerID, shortcode: setting&.sender_id
    )
    Net::HTTP.get_response(uri)
  end

  def send_talksasa(phone, message)
    setting = SmsSetting.find_by(sms_provider: 'Talk Sasa')
    formatted_phone = "254#{phone.to_s.gsub(/\A0/, '')}"
    uri = URI.parse("https://bulksms.talksasa.com/api/v3/sms/send")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Authorization"] = "Bearer #{setting&.api_key}"
    request["Content-Type"] = "application/json"
    request.body = { recipient: formatted_phone, sender_id: setting&.sender_id, type: "plain", message: message }.to_json
    http.request(request)
  end
end