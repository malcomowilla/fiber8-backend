# Extends HotspotVoucher expirations for an outage and (optionally) SMS's
# affected customers.
#
# NOTE: HotspotVoucher#expiration is a real datetime column — reading it
# returns an ActiveSupport::TimeWithZone, not a formatted string. It's only
# ever *displayed* as "August 24, 2026 at 03:15 PM" (see
# HotspotVouchersController), the underlying attribute is a proper
# timestamp. No string parsing needed — just read/write the Time object.
#
# - HotspotPackage#nas_router stores the router's NAME (String).
# - Radius accounts get expiry pushed via RadCheck's 'Expiration' attribute,
#   same as HotspotVouchersController#create_voucher_radcheck.
# - Native (non-radius) accounts only get the app-level `expiration` column
#   extended here — if you enforce native expiry via a background sweep
#   job, it just needs to read the updated column, no router call needed.
class HotspotIncidentCompensationService
  Result = Struct.new(:compensated_count, :sms_sent_count, :voucher_ids, keyword_init: true)

  def initialize(account, grace_duration)
    @account = account
    @grace_duration = grace_duration
  end

  # scope: HotspotVoucher relation already filtered to affected routers /
  # active-vs-expired rule (built by the caller).
  def compensate(scope, notify: true, company_name: nil)
    compensated_ids = []

    scope.find_each do |voucher|
      new_expiration_time = compensated_expiration_for(voucher)
      next unless new_expiration_time

      voucher.update(
        expiration: new_expiration_time,
        status: 'active'
      )

      sync_radius_expiration(voucher, new_expiration_time) if router_uses_radius?
      compensated_ids << voucher.id
    end

    sms_sent = notify ? notify_customers(HotspotVoucher.where(id: compensated_ids), company_name) : 0

    Result.new(compensated_count: compensated_ids.size, sms_sent_count: sms_sent, voucher_ids: compensated_ids)
  end

  private

  def compensated_expiration_for(voucher)
    current_expiration = voucher.expiration

    if voucher.status == 'active' && current_expiration.present?
      current_expiration + @grace_duration
    else
      # expired (or missing expiration) vouchers are graced starting now
      Time.current + @grace_duration
    end
  end

  def router_uses_radius?
    setting = NasSetting.find_by(account_id: @account.id)
    setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
  end

  def sync_radius_expiration(voucher, expiration_time)
    RadCheck.find_or_initialize_by(
      username: voucher.voucher,
      account_id: @account.id,
      radiusattribute: 'Expiration'
    ).update!(op: ':=', value: expiration_time.strftime("%d %b %Y %H:%M:%S"))
  rescue => e
    Rails.logger.error "HotspotIncidentCompensationService: RadCheck update failed for #{voucher.voucher}: #{e.message}"
  end

  def notify_customers(vouchers, company_name)
    sent = 0
    provider = @account.sms_provider_setting&.sms_provider

    vouchers.each do |voucher|
      next if voucher.phone.blank?
      message = compensation_message(voucher, company_name)

      begin
        case provider
        when 'SMS leopard' then send_sms_leopard(voucher.phone, message)
        when 'TextSms'     then send_textsms(voucher.phone, message)
        when 'Talk Sasa'   then send_talksasa(voucher.phone, message)
        else next
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
      company_name: company_name || @account.company_setting&.company_name
    }
    return template.render(data) if template

    "We're sorry for today's service interruption. Your voucher #{voucher.voucher} has been " \
      "extended as compensation. Thank you for your patience. (FROM: #{data[:company_name]})"
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