
# class HotspotIncidentCompensationService
#   Result = Struct.new(:compensated_count, :sms_sent_count,
#    :voucher_ids, keyword_init: true)

#   def initialize(account, grace_duration)
#     @account = account
#     @grace_duration = grace_duration
#   end

#   def compensate(scope, notify: true, company_name: nil)
#     compensated_ids = []

#     deduped_scope(scope).find_each do |voucher|
#       new_expiration_time = compensated_expiration_for(voucher)
#       next unless new_expiration_time

#       unless voucher.update(expiration: new_expiration_time, status: 'active')
#         Rails.logger.error "HotspotIncidentCompensationService: failed to update voucher #{voucher.id}: #{voucher.errors.full_messages.join(', ')}"
#         next
#       end

#       sync_to_router(voucher, new_expiration_time)
#       compensated_ids << voucher.id
#     end

#     sms_sent = notify ? notify_customers(HotspotVoucher.where(id: compensated_ids), company_name) : 0

#     Result.new(compensated_count: compensated_ids.size, sms_sent_count: sms_sent, voucher_ids: compensated_ids)
#   end

#   private

#   def deduped_scope(scope)
#     phoned_ids    = scope.where.not(phone: [nil, '']).group(:phone).maximum(:id).values
#     phoneless_ids = scope.where(phone: [nil, '']).pluck(:id)
#     HotspotVoucher.where(id: phoned_ids + phoneless_ids)
#   end

#   def compensated_expiration_for(voucher)
#     current_expiration = voucher.expiration

#     if voucher.status == 'active' && current_expiration.present?
#       current_expiration + @grace_duration
#     else
#       Time.current + @grace_duration
#     end
#   end

#   def router_uses_radius?
#     setting = NasSetting.find_by(account_id: @account.id)
#     setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
#   end

#   def real_time_mode?
#     @account.hotspot_setting&.voucher_expiration == 'Real-time expiration'
#   end

#   def sync_to_router(voucher, expiration_time)
#     if router_uses_radius?
#       real_time_mode? ? sync_radius_expiration(voucher, expiration_time) : sync_radius_accumulated(voucher)
#     elsif real_time_mode?
#       sync_native_bare(voucher)
#     end
#     # native + accumulated: intentionally not synced — see class comment
#   end

#   def sync_radius_expiration(voucher, expiration_time)
#     RadCheck.find_or_initialize_by(
#       username: voucher.voucher,
#       account_id: @account.id,
#       radiusattribute: 'Expiration'
#     ).update!(op: ':=', value: expiration_time.strftime("%d %b %Y %H:%M:%S"))
#   rescue => e
#     Rails.logger.error "HotspotIncidentCompensationService: RadCheck Expiration update failed for #{voucher.voucher}: #{e.message}"
#   end

#   def sync_radius_accumulated(voucher)
#     record = RadCheck.find_or_initialize_by(
#       username: voucher.voucher,
#       account_id: @account.id,
#       radiusattribute: 'Max-All-Session'
#     )
#     current_seconds = record.value.to_i
#     record.update!(op: ':=', value: (current_seconds + @grace_duration.to_i).to_s)
#   rescue => e
#     Rails.logger.error "HotspotIncidentCompensationService: RadCheck Max-All-Session update failed for #{voucher.voucher}: #{e.message}"
#   end

#   def sync_native_bare(voucher)
#     package = HotspotPackage.find_by(name: voucher.package, account_id: @account.id)
#     return unless package

#     nas = NasRouter.find_by(name: package.nas_router, account_id: @account.id)
#     return unless nas

#     RestClient::Request.execute(
#       method: :put,
#       url: "http://#{nas.ip_address}/rest/ip/hotspot/user",
#       user: nas.username.to_s, password: nas.password.to_s,
#       payload: { name: voucher.voucher, password: voucher.voucher, profile: package.name }.to_json,
#       headers: { content_type: :json },
#       timeout: 10, open_timeout: 5
#     )
#     voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)
#   rescue => e
#     Rails.logger.error "HotspotIncidentCompensationService: native sync failed for #{voucher.voucher}: #{e.message}"
#     voucher.update(sync_status: 'failed', sync_error: e.message)
#   end

#   def notify_customers(vouchers, company_name)
#     sent = 0
#     provider = @account.sms_provider_setting&.sms_provider

#     vouchers.find_each do |voucher|
#       next if voucher.phone.blank?

#       begin
#         message = compensation_message(voucher.reload, company_name)
#         case provider
#         when 'SMS leopard' then send_sms_leopard(voucher.phone, message)
#         when 'TextSms'     then send_textsms(voucher.phone, message, voucher.account_id)
#         when 'Talk Sasa'   then send_talksasa(voucher.phone, message)
#         else
#           next
#         end
#         sent += 1
#       rescue => e
#         Rails.logger.error "HotspotIncidentCompensationService: SMS failed for #{voucher.phone}: #{e.message}"
#       end
#     end

#     sent
#   end

#   def compensation_message(voucher, company_name)
#     template = HotspotSmsTemplate.active_for(@account.id, 'incident_compensation')
#     data = {
#       customer_phone: voucher.phone,
#       voucher_code: voucher.voucher,
#       plan_name: voucher.package,
#       validity: voucher.expiration&.strftime("%B %d, %Y at %I:%M %p") || "your next login",
#       company_name: company_name || @account.company_setting&.company_name
#     }
#     return template.render(data) if template

#     "We're sorry for today's service interruption. Your voucher #{voucher.voucher} has been " \
#       "extended and is now valid until #{data[:validity]}. Thank you for your patience. (FROM: #{data[:company_name]})"
#   end

#   def send_sms_leopard(phone, message, account_id)
#     setting = SmsSetting.find_by(sms_provider: 'SMS leopard')
#     uri = URI("https://api.smsleopard.com/v1/sms/send")
#     uri.query = URI.encode_www_form(
#       username: setting&.api_key, password: setting&.api_secret,
#       message: message, destination: phone, source: "SMS_TEST"
#     )
#     response = Net::HTTP.get_response(uri)
#     if response.is_a?(Net::HTTPSuccess)
#         sms_data = JSON.parse(response.body) rescue {}

#         SystemAdminSm.create!(
#           user: phone,
#           message: message,
#           status: sms_data['status'],
#           date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
#           system_user: 'system',
#           account_id: account_id,
#           sms_provider: 'SMS leopard'
#         )
#       else
#         Rails.logger.info "[SendSmsHotspotService] Failed to send SMS with Talk Sasa: #{response.code} - #{response.body}"

#         SystemAdminSm.create!(
#           user: phone,
#           message: message,
#           status: "Failed: #{response.code}",
#           date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
#           system_user: 'system',
#           account_id: account_id,
#           sms_provider: 'SMS leopard'
#         )
#       end
#   end







#   def send_textsms(phone, message, account_id)
#     setting = SmsSetting.find_by(sms_provider: 'TextSms')
#     uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
#     uri.query = URI.encode_www_form(
#       apikey: setting&.api_key, message: message, mobile: phone,
#       partnerID: setting&.partnerID, shortcode: setting&.sender_id
#     )
#     response = Net::HTTP.get_response(uri)
#     if response.is_a?(Net::HTTPSuccess)
#         sms_data = JSON.parse(response.body) rescue {}

#         SystemAdminSm.create!(
#           user: phone,
#           message: message,
#           status: sms_data['status'],
#           date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
#           system_user: 'system',
#           account_id: account_id,
#           sms_provider: 'Text Sms'
#         )
#       else
#         Rails.logger.info "[SendSmsHotspotService] Failed to send SMS with Talk Sasa: #{response.code} - #{response.body}"

#         SystemAdminSm.create!(
#           user: phone,
#           message: message,
#           status: "Failed: #{response.code}",
#           date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
#           system_user: 'system',
#           account_id: account_id,
#           sms_provider: 'Text Sms'
#         )
#       end
#   end





#   def send_talksasa(phone, message)
#     setting = SmsSetting.find_by(sms_provider: 'Talk Sasa')
#     formatted_phone = "254#{phone.to_s.gsub(/\A0/, '')}"
#     uri = URI.parse("https://bulksms.talksasa.com/api/v3/sms/send")
#     http = Net::HTTP.new(uri.host, uri.port)
#     http.use_ssl = true
#     request = Net::HTTP::Post.new(uri.request_uri)
#     request["Authorization"] = "Bearer #{setting&.api_key}"
#     request["Content-Type"] = "application/json"
#     request.body = { recipient: formatted_phone, sender_id: setting&.sender_id, type: "plain", message: message }.to_json
#     http.request(request)
#   end


# end



class HotspotIncidentCompensationService
  Result = Struct.new(:compensated_count, :sms_sent_count,
   :voucher_ids, keyword_init: true)

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
    # native + accumulated: intentionally not synced
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

  # Only counts an SMS as sent when the provider actually returned 2xx.
  def notify_customers(vouchers, company_name)
    sent = 0
    provider = @account.sms_provider_setting&.sms_provider

    vouchers.find_each do |voucher|
      next if voucher.phone.blank?

      begin
        message = compensation_message(voucher.reload, company_name)
        delivered =
          case provider
          when 'SMS leopard' then send_sms_leopard(voucher.phone, message)
          when 'TextSms'     then send_textsms(voucher.phone, message)
          when 'Talk Sasa'   then send_talksasa(voucher.phone, message)
          else
            next
          end
        sent += 1 if delivered
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

  # Logs every attempt (success or failure) to SystemAdminSm and returns true
  # only when the provider responded 2xx. A logging failure never changes the
  # result, because the SMS has already gone out by then.
  def log_sms(phone, message, response, provider_label)
    success = response.is_a?(Net::HTTPSuccess)

    status =
      if success
        sms_data = (JSON.parse(response.body) rescue {})
        sms_data = {} unless sms_data.is_a?(Hash)
        sms_data['status'] || 'Sent'
      else
        Rails.logger.info "[HotspotIncidentCompensationService] Failed to send SMS with #{provider_label}: #{response.code} - #{response.body}"
        "Failed: #{response.code}"
      end

    begin
      SystemAdminSm.create!(
        user: phone,
        message: message,
        status: status,
        date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
        system_user: 'system',
        account_id: @account.id,
        sms_provider: provider_label
      )
    rescue => e
      Rails.logger.error "HotspotIncidentCompensationService: SystemAdminSm log failed for #{phone}: #{e.message}"
    end

    success
  end

  def send_sms_leopard(phone, message)
    setting = SmsSetting.find_by(sms_provider: 'SMS leopard')
    uri = URI("https://api.smsleopard.com/v1/sms/send")
    uri.query = URI.encode_www_form(
      username: setting&.api_key, password: setting&.api_secret,
      message: message, destination: phone, source: "SMS_TEST"
    )
    response = Net::HTTP.get_response(uri)
    log_sms(phone, message, response, 'SMS leopard')
  end

  def send_textsms(phone, message)
    setting = SmsSetting.find_by(sms_provider: 'TextSms')
    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    uri.query = URI.encode_www_form(
      apikey: setting&.api_key, message: message, mobile: phone,
      partnerID: setting&.partnerID, shortcode: setting&.sender_id
    )
    response = Net::HTTP.get_response(uri)
    log_sms(phone, message, response, 'Text Sms')
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
    response = http.request(request)
    log_sms(phone, message, response, 'Talk Sasa')
  end
end

