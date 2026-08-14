# # app/services/hotspot_sms_service.rb
# class HotspotSmsService
#   # Entry point — picks the right provider and sends.
#   # Called from SendSmsHotspotJob and from the controller's
#   # send_voucher_to_phone_number action.
#   def self.send_voucher_sms(voucher, tenant)
#     sms_setting = tenant.sms_provider_setting
#     if sms_setting.blank?
#       Rails.logger.info "[HotspotSmsService] No SMS provider for tenant #{tenant.id}, skipping"
#       return
#     end

#     voucher.update!(sms_sent: true, sms_sent_at_voucher: Time.current)

#     message = build_message(voucher, tenant)

#     case sms_setting.sms_provider
#     when "SMS leopard" then send_via_sms_leopard(voucher, tenant, message)
#     when "TextSms"     then send_via_text_sms(voucher, tenant, message)
#     when "Talk Sasa"   then send_via_talk_sasa(voucher, tenant, message)
#     else
#       Rails.logger.info "[HotspotSmsService] Unknown provider #{sms_setting.sms_provider}"
#     end
#   end

#   # ── Message builder — uses HotspotSmsTemplate if one is configured,
#   # falls back to a sensible default. Same logic as the controller's
#   # render_hotspot_sms / build_voucher_sms_data helpers, but callable
#   # from anywhere without inheriting ApplicationController. ──────────────
#   def self.build_message(voucher, tenant)
#     package      = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
#     company_name = tenant.company_setting&.company_name.to_s

#     data = {
#       customer_phone: voucher.phone,
#       plan_name:      package&.name,
#       voucher_code:   voucher.voucher,
#       username:       voucher.voucher,
#       password:       voucher.voucher,
#       validity:       voucher.expiration&.strftime("%B %d, %Y at %I:%M %p"),
#       price:          package&.price,
#       company_name:   company_name,
#       voucher_count:  package&.shared_users,
#       voucher_list:   HotspotSmsTemplate.format_voucher_list(
#         [{ code: voucher.voucher, username: voucher.voucher, password: voucher.voucher }]
#       ),
#     }

#     template = HotspotSmsTemplate.active_for(tenant.id, 'single')
#     return template.render(data) if template

#     # Default fallback
#     expiry_str = data[:validity] ? " Valid until #{data[:validity]}." : ""
#     "Your voucher code is: #{voucher.voucher}.#{expiry_str} Enjoy browsing! (#{company_name})"
#   end

#   # ── Providers ────────────────────────────────────────────────────────────

#   def self.send_via_sms_leopard(voucher, tenant, message)
#     setting    = SmsSetting.find_by(account_id: tenant.id, sms_provider: 'SMS leopard')
#     api_key    = setting&.api_key
#     api_secret = setting&.api_secret
#     return Rails.logger.warn "[HotspotSmsService] SMS Leopard: missing credentials" unless api_key

#     uri = URI("https://api.smsleopard.com/v1/sms/send")
#     uri.query = URI.encode_www_form(
#       username:    api_key,
#       password:    api_secret,
#       message:     message,
#       destination: voucher.phone,
#       source:      "SMS_TEST"
#     )
#     response = Net::HTTP.get_response(uri)
#     Rails.logger.info "[HotspotSmsService] SMS Leopard → #{response.code}: #{response.body}"

#     if response.is_a?(Net::HTTPSuccess)
#       parsed = JSON.parse(response.body) rescue {}
#       record = parsed.dig('recipients', 0) || {}
#       SystemAdminSm.create!(
#         user:        record['number'] || voucher.phone,
#         message:     message,
#         status:      record['status'] || response.code,
#         date:        Time.current.strftime("%B %d, %Y at %I:%M %p"),
#         system_user: "system",
#         sms_provider: 'SMS leopard'
#       )
#     end
#   end

#   def self.send_via_text_sms(voucher, tenant, message)
#     setting   = SmsSetting.find_by(account_id: tenant.id, sms_provider: 'TextSms')
#     api_key   = setting&.api_key
#     partner_id = setting&.partnerID
#     shortcode = setting&.sender_id
#     return Rails.logger.warn "[HotspotSmsService] TextSms: missing credentials" unless api_key

#     uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
#     uri.query = URI.encode_www_form(
#       apikey:    api_key,
#       message:   message,
#       mobile:    voucher.phone,
#       partnerID: partner_id,
#       shortcode: shortcode
#     )
#     response = Net::HTTP.get_response(uri)
#     Rails.logger.info "[HotspotSmsService] TextSms → #{response.code}: #{response.body}"

#     if response.is_a?(Net::HTTPSuccess)
#       parsed = JSON.parse(response.body) rescue {}
#       record = parsed.dig('responses', 0) || {}
#       SystemAdminSm.create!(
#         user:        record['mobile'] || voucher.phone,
#         message:     message,
#         status:      record['response-description'] || response.code,
#         date:        Time.current.strftime("%B %d, %Y at %I:%M %p"),
#         system_user: "system",
#         sms_provider: 'TextSms'
#       )
#     end
#   end

#   def self.send_via_talk_sasa(voucher, tenant, message)
#     setting   = SmsSetting.find_by(account_id: tenant.id, sms_provider: 'Talk Sasa')
#     api_key   = setting&.api_key
#     sender_id = setting&.sender_id
#     return Rails.logger.warn "[HotspotSmsService] TalkSasa: missing credentials" unless api_key

#     formatted_phone = "254#{voucher.phone.gsub(/\A0/, '')}"

#     uri  = URI.parse("https://bulksms.talksasa.com/api/v3/sms/send")
#     http = Net::HTTP.new(uri.host, uri.port)
#     http.use_ssl = true

#     req = Net::HTTP::Post.new(uri.request_uri)
#     req["Authorization"] = "Bearer #{api_key}"
#     req["Content-Type"]  = "application/json"
#     req["Accept"]        = "application/json"
#     req.body = { recipient: formatted_phone, sender_id: sender_id,
#                  type: "plain", message: message }.to_json

#     response = http.request(req)
#     Rails.logger.info "[HotspotSmsService] TalkSasa → #{response.code}: #{response.body}"

#     if response.is_a?(Net::HTTPSuccess)
#       parsed = JSON.parse(response.body) rescue {}
#       SystemAdminSm.create!(
#         user:        voucher.phone,
#         message:     message,
#         status:      parsed['status'] || response.code,
#         date:        Time.current.strftime("%B %d, %Y at %I:%M %p"),
#         system_user: "system",
#         sms_provider: 'Talk Sasa'
#       )
#     end
#   end
# end
# 





# app/services/hotspot_sms_service.rb
class HotspotSmsService
  # Entry point — picks the right provider and sends.
  # Called from SendSmsHotspotJob and from the controller's
  # send_voucher_to_phone_number action.
  def self.send_voucher_sms(voucher, tenant)
    sms_setting = tenant.sms_provider_setting
    if sms_setting.blank?
      Rails.logger.info "[HotspotSmsService] No SMS provider for tenant #{tenant.id}, skipping"
      return
    end

    voucher.update!(sms_sent: true, sms_sent_at_voucher: Time.current)

    message = build_message(voucher, tenant)

    case sms_setting.sms_provider
    when "SMS leopard" then send_via_sms_leopard(voucher, tenant, message)
    when "TextSms"     then send_via_text_sms(voucher, tenant, message)
    when "Talk Sasa"   then send_via_talk_sasa(voucher, tenant, message)
    else
      Rails.logger.info "[HotspotSmsService] Unknown provider #{sms_setting.sms_provider}"
    end
  end

  # ── Message builder — uses HotspotSmsTemplate if one is configured,
  # falls back to a sensible default. Same logic as the controller's
  # render_hotspot_sms / build_voucher_sms_data helpers, but callable
  # from anywhere without inheriting ApplicationController. ──────────────
  def self.build_message(voucher, tenant)
    package      = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
    company_name = tenant.company_setting&.company_name.to_s

    data = {
      customer_phone: voucher.phone,
      plan_name:      package&.name,
      voucher_code:   voucher.voucher,
      username:       voucher.voucher,
      password:       voucher.voucher,
      validity:       voucher.expiration&.strftime("%B %d, %Y at %I:%M %p"),
      price:          package&.price,
      company_name:   company_name,
      voucher_count:  package&.shared_users,
      voucher_list:   HotspotSmsTemplate.format_voucher_list(
        [{ code: voucher.voucher, username: voucher.voucher, password: voucher.voucher }]
      ),
    }

    template = HotspotSmsTemplate.active_for(tenant.id, 'single')
    return template.render(data) if template

    # Default fallback
    expiry_str = data[:validity] ? " Valid until #{data[:validity]}." : ""
    "Your voucher code is: #{voucher.voucher}.#{expiry_str} Enjoy browsing! (#{company_name})"
  end

  # ── Providers ────────────────────────────────────────────────────────────

  def self.send_via_sms_leopard(voucher, tenant, message)
    setting    = SmsSetting.find_by(account_id: tenant.id, sms_provider: 'SMS leopard')
    api_key    = setting&.api_key
    api_secret = setting&.api_secret
    return Rails.logger.warn "[HotspotSmsService] SMS Leopard: missing credentials" unless api_key

    uri = URI("https://api.smsleopard.com/v1/sms/send")
    uri.query = URI.encode_www_form(
      username:    api_key,
      password:    api_secret,
      message:     message,
      destination: voucher.phone,
      source:      "SMS_TEST"
    )
    response = Net::HTTP.get_response(uri)
    Rails.logger.info "[HotspotSmsService] SMS Leopard → #{response.code}: #{response.body}"

    if response.is_a?(Net::HTTPSuccess)
      parsed = JSON.parse(response.body) rescue {}
      record = parsed.dig('recipients', 0) || {}
      SystemAdminSm.create!(
        user:        record['number'] || voucher.phone,
        message:     message,
        status:      record['status'] || response.code,
        date:        Time.current.strftime("%B %d, %Y at %I:%M %p"),
        system_user: "system",
        sms_provider: 'SMS leopard'
      )
    end
  end

  def self.send_via_text_sms(voucher, tenant, message)
    setting   = SmsSetting.find_by(account_id: tenant.id, sms_provider: 'TextSms')
    api_key   = setting&.api_key
    partner_id = setting&.partnerID
    shortcode = setting&.sender_id
    return Rails.logger.warn "[HotspotSmsService] TextSms: missing credentials" unless api_key

    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    uri.query = URI.encode_www_form(
      apikey:    api_key,
      message:   message,
      mobile:    voucher.phone,
      partnerID: partner_id,
      shortcode: shortcode
    )
    response = Net::HTTP.get_response(uri)
    Rails.logger.info "[HotspotSmsService] TextSms → #{response.code}: #{response.body}"

    if response.is_a?(Net::HTTPSuccess)
      parsed = JSON.parse(response.body) rescue {}
      record = parsed.dig('responses', 0) || {}
      SystemAdminSm.create!(
        user:        record['mobile'] || voucher.phone,
        message:     message,
        status:      record['response-description'] || response.code,
        date:        Time.current.strftime("%B %d, %Y at %I:%M %p"),
        system_user: "system",
        sms_provider: 'TextSms'
      )
    end
  end

  def self.send_via_talk_sasa(voucher, tenant, message)
    setting   = SmsSetting.find_by(account_id: tenant.id, sms_provider: 'Talk Sasa')
    api_key   = setting&.api_key
    sender_id = setting&.sender_id
    return Rails.logger.warn "[HotspotSmsService] TalkSasa: missing credentials" unless api_key

    formatted_phone = "254#{voucher.phone.gsub(/\A0/, '')}"

    uri  = URI.parse("https://bulksms.talksasa.com/api/v3/sms/send")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri.request_uri)
    req["Authorization"] = "Bearer #{api_key}"
    req["Content-Type"]  = "application/json"
    req["Accept"]        = "application/json"
    req.body = { recipient: formatted_phone, sender_id: sender_id,
                 type: "plain", message: message }.to_json

    response = http.request(req)
    Rails.logger.info "[HotspotSmsService] TalkSasa → #{response.code}: #{response.body}"

    if response.is_a?(Net::HTTPSuccess)
      parsed = JSON.parse(response.body) rescue {}
      SystemAdminSm.create!(
        user:        voucher.phone,
        message:     message,
        status:      parsed['status'] || response.code,
        date:        Time.current.strftime("%B %d, %Y at %I:%M %p"),
        system_user: "system",
        sms_provider: 'Talk Sasa'
      )
    end
  end
end