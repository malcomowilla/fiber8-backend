# class HotspotExpirationJob
#   include Sidekiq::Job
#   queue_as :default
#   sidekiq_options lock: :until_executed, lock_timeout: 0

#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
#         process_expired_vouchers(tenant)
#         process_hotspot_plan_expiry(tenant)
#       end
#     end
#   end

#   private

#   def process_expired_vouchers(tenant)
#     expired_vouchers = HotspotVoucher
#       .where('expiration < ?', Time.current)
#       .where(account_id: tenant.id)
#       .where(sms_sent_at: nil)

#     expired_vouchers.find_each do |voucher|
#       # Isolated per-voucher so one bad record (SSH failure, SMS API error,
#       # nil template, etc.) can't abort find_each and silently skip every
#       # tenant/voucher that would have been processed after it.
#       begin
#         voucher.update_column(:status, 'expired')

#         if voucher.used_voucher && voucher.sms_sent_at.nil?
#           send_expiration_sms(voucher, tenant)
#           voucher.update!(sms_sent_at: Time.current)
#         end

#         logout_hotspot_user(voucher, tenant)
#       rescue StandardError => e
#         Rails.logger.error(
#           "HotspotExpirationJob: failed processing voucher ##{voucher.id} " \
#           "(account ##{tenant.id}): #{e.class} - #{e.message}"
#         )
#       end
#     end
#   end

#   def process_hotspot_plan_expiry(tenant)
#     hotspot_subscriptions = HotspotVoucher.where(account_id: tenant.id)

#     hotspot_subscriptions.find_each do |subscription|
#       next unless subscription.voucher.present?

#       begin
#         plan = tenant&.hotspot_and_dial_plan
#         expired_hotspot = plan&.expiry.present? && plan.expiry <= Time.current

#         if expired_hotspot
#           RadCheck.find_or_create_by!(
#             username: subscription.voucher,
#             radiusattribute: 'Auth-Type',
#             account_id: subscription.account_id,
#             op: ':=',
#             value: 'Reject'
#           )
#         else
#           RadCheck.where(
#             username: subscription.voucher,
#             account_id: subscription.account_id,
#             radiusattribute: 'Auth-Type',
#             value: 'Reject'
#           ).destroy_all
#         end
#       rescue StandardError => e
#         Rails.logger.error(
#           "HotspotExpirationJob: RADIUS update failed for voucher " \
#           "##{subscription.id} (account ##{tenant.id}): #{e.class} - #{e.message}"
#         )
#       end
#     end
#   end

#   def calculate_expiration_voucher(package, voucher_created, account_id)
#     hotspot_package = HotspotPackage.find_by(name: package, account_id: account_id)
#     return unless hotspot_package

#     expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
#       case hotspot_package.validity_period_units.downcase
#       when 'days'    then Time.current + hotspot_package.validity.days
#       when 'hours'   then Time.current + hotspot_package.validity.hours
#       when 'minutes' then Time.current + hotspot_package.validity.minutes
#       else nil
#       end
#     end

#     if expiration_time.present?
#       voucher_created.update(expiration: expiration_time)
#     end

#     { expiration: expiration_time }
#   end

#   def logout_hotspot_user(voucher, tenant)
#     hotspot_package = HotspotPackage.find_by(name: voucher.package, account_id: tenant.id)
#     return unless hotspot_package

#     router = NasRouter.find_by(name: hotspot_package.nas_router, account_id: tenant.id)
#     return unless router

#     router_ip = router.ip_address
#     router_username = router.username
#     router_password = router.password

#     remove_command = "/ip hotspot active remove [find user=#{voucher.voucher}]"

#     begin
#       Net::SSH.start(
#         router_ip,
#         router_username,
#         password: router_password,
#         verify_host_key: :never,
#         non_interactive: true
#       ) do |ssh|
#         output = ssh.exec!(remove_command)
#         Rails.logger.info(
#           "Successfully removed user #{voucher.voucher} from router #{router.name || router_ip}: #{output}"
#         )
#       end
#     rescue Net::SSH::AuthenticationFailed
#       Rails.logger.info("SSH authentication failed for MikroTik router #{router.name || router_ip}")
#     rescue StandardError => e
#       Rails.logger.info(
#         "Failed to logout user #{voucher.voucher} from router #{router.name || router_ip}: #{e.message}"
#       )
#     end
#   end

#   def send_expiration_sms(voucher, tenant)
#     provider = tenant&.sms_provider_setting.present? && tenant.sms_provider_setting&.sms_provider

#     case provider
#     when 'TextSms'
#       send_expiration_text_sms(voucher.phone, voucher, tenant)
#     when 'SMS leopard'
#       send_expiration(voucher.phone, voucher, tenant)
#     when 'Talk Sasa'
#       send_expiration_talksasa(voucher.phone, voucher, tenant)
#     else
#       Rails.logger.info "No valid SMS provider configured for account #{tenant.id}"
#     end
#   end

#   def send_expiration_talksasa(phone_number, voucher, tenant)
#     formatted_phone_number = "254#{phone_number.gsub(/\A0/, '')}"

#     sms_setting = tenant&.sms_setting
#     api_key = sms_setting&.api_key
#     sender_id = sms_setting&.sender_id

#     original_message = render_expiration_message(tenant, voucher)

#     uri = URI.parse("https://bulksms.talksasa.com/api/v3/sms/send")
#     http = Net::HTTP.new(uri.host, uri.port)
#     http.use_ssl = true

#     request = Net::HTTP::Post.new(uri.request_uri)
#     request["Authorization"] = "Bearer #{api_key}"
#     request["Content-Type"] = "application/json"
#     request["Accept"] = "application/json"
#     request.body = {
#       recipient: formatted_phone_number,
#       sender_id: sender_id,
#       type: "plain",
#       message: original_message
#     }.to_json

#     begin
#       response = http.request(request)
#       Rails.logger.info "TalkSasa Response: #{response.body}"

#       if response.is_a?(Net::HTTPSuccess)
#         sms_data = JSON.parse(response.body)
#         sms_status = sms_data['status']

#         SystemAdminSm.create!(
#           user: phone_number,
#           message: original_message,
#           status: sms_status,
#           date: Time.current,
#           system_user: 'system',
#           account_id: tenant.id,
#           sms_provider: 'Talk Sasa'
#         )
#         Rails.logger.info "Sent message successfully with talk sasa"
#       else
#         Rails.logger.info "Failed to send SMS with talk sasa: #{response.code} - #{response.body}"
#       end
#     rescue StandardError => e
#       Rails.logger.error "TalkSasa SMS error for account #{tenant.id}: #{e.class} - #{e.message}"
#     end
#   end

#   def send_expiration(phone_number, voucher, tenant)
#     api_key = nil
#     api_secret = nil
#     sms_setting = tenant&.sms_setting

#     if sms_setting&.sms_provider == 'SMS leopard'
#       api_key = sms_setting.api_key
#       api_secret = sms_setting.api_secret
#     end

#     original_message = render_expiration_message(tenant, voucher)
#     sender_id = "SMS_TEST"
#     uri = URI("https://api.smsleopard.com/v1/sms/send")
#     params = {
#       username: api_key,
#       password: api_secret,
#       message: original_message,
#       destination: phone_number,
#       source: sender_id
#     }
#     uri.query = URI.encode_www_form(params)

#     begin
#       response = Net::HTTP.get_response(uri)
#       handle_sms_leopard_response(response, original_message, phone_number, tenant)
#     rescue StandardError => e
#       Rails.logger.error "SMS Leopard error for account #{tenant.id}: #{e.class} - #{e.message}"
#     end
#   end

#   def send_expiration_text_sms(phone_number, voucher, tenant)
#     api_key = nil
#     partnerID = nil
#     shortcode = nil
#     sms_setting = tenant&.sms_setting

#     if sms_setting&.sms_provider == 'TextSms'
#       api_key = sms_setting.api_key
#       partnerID = sms_setting.partnerID
#       shortcode = sms_setting.sender_id
#     end

#     original_message = render_expiration_message(tenant, voucher)
#     uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
#     params = {
#       apikey: api_key,
#       message: original_message,
#       mobile: phone_number,
#       partnerID: partnerID,
#       shortcode: shortcode
#     }
#     uri.query = URI.encode_www_form(params)

#     begin
#       response = Net::HTTP.get_response(uri)
#       handle_textsms_response(response, original_message, phone_number, tenant)
#     rescue StandardError => e
#       Rails.logger.error "TextSms error for account #{tenant.id}: #{e.class} - #{e.message}"
#     end
#   end

#   def handle_textsms_response(response, message, phone_number, tenant)
#     sms_recipient = phone_number
#     sms_status = nil

#     if response.is_a?(Net::HTTPSuccess)
#       begin
#         sms_data = JSON.parse(response.body)
#         sms_recipient = sms_data.dig('responses', 0, 'mobile') || phone_number
#         sms_status = sms_data.dig('responses', 0, 'response-description')
#         Rails.logger.info "Recipient: #{sms_recipient}, Status: #{sms_status}"
#       rescue JSON::ParserError => e
#         Rails.logger.error "TextSms: failed to parse response body: #{e.message}"
#         sms_status = 'parse_error'
#       end
#     else
#       Rails.logger.error "Failed to send message: #{response.body}"
#       sms_status = "http_error_#{response.code}"
#     end

#     SystemAdminSm.create!(
#       user: sms_recipient,
#       message: message,
#       status: sms_status,
#       date: Time.current,
#       system_user: 'system',
#       sms_provider: 'Text Sms',
#       account_id: tenant.id
#     )
#   end

#   def handle_sms_leopard_response(response, message, phone_number, tenant)
#     sms_recipient = phone_number
#     sms_status = nil

#     if response.is_a?(Net::HTTPSuccess)
#       begin
#         sms_data = JSON.parse(response.body)
#         sms_recipient = sms_data.dig('responses', 0, 'mobile') || phone_number
#         sms_status = sms_data.dig('responses', 0, 'response-description')
#         Rails.logger.info "Recipient: #{sms_recipient}, Status: #{sms_status}"
#       rescue JSON::ParserError => e
#         Rails.logger.error "SMS Leopard: failed to parse response body: #{e.message}"
#         sms_status = 'parse_error'
#       end
#     else
#       Rails.logger.error "Failed to send message: #{response.body}"
#       sms_status = "http_error_#{response.code}"
#     end

#     SystemAdminSm.create!(
#       user: sms_recipient,
#       message: message,
#       status: sms_status,
#       date: Time.current,
#       system_user: 'system',
#       sms_provider: 'SMS leopard',
#       account_id: tenant.id
#     )
#   end

#   def render_expiration_message(tenant, voucher)
#     template = HotspotSmsTemplate.find_by(account_id: tenant.id, category: 'expiration', active: true)
#     data = {
#       customer_phone: voucher.phone,
#       voucher_code: voucher.voucher,
#       plan_name: voucher.package,
#       company_name: tenant.company_setting&.company_name
#     }
#     template ? template.render(data) : "Hello, your voucher #{voucher.voucher} is expired renew now to stay connected."
#   end
# end
# 








class HotspotExpirationJob
  include Sidekiq::Job

  queue_as :default

  sidekiq_options lock: :until_executed, lock_timeout: 0

  SSH_CONNECT_TIMEOUT = 5 # seconds - fail fast instead of hanging on a dead router

  def perform
    @failed_routers = {} # router_ip => true, reset per job run, avoids re-timing-out on the same dead router for every voucher

    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        process_expired_vouchers(tenant)
        process_hotspot_plan_expiry(tenant)
      end
    end
  end

  private

  def process_expired_vouchers(tenant)
    # Was filtering on sms_sent_at, which only ever gets set for used_voucher == true
    # vouchers. Unused vouchers never got sms_sent_at set, so they matched this query
    # forever and got reprocessed (incl. re-attempting SSH logout) on every single run.
    # Filter on status instead so a voucher stops being picked up once it's actually
    # been processed.
    expired_vouchers = HotspotVoucher
      .where('expiration < ?', Time.current)
      .where(account_id: tenant.id)
      .where.not(status: 'expired')

    expired_vouchers.find_each do |voucher|
      begin
        voucher.update_column(:status, 'expired')

        if voucher.used_voucher && voucher.sms_sent_at.nil?
          send_expiration_sms(voucher, tenant)
          voucher.update!(sms_sent_at: Time.current)
        end

        logout_hotspot_user(voucher, tenant)
      rescue StandardError => e
        Rails.logger.error(
          "HotspotExpirationJob: failed processing voucher ##{voucher.id} " \
          "(account ##{tenant.id}): #{e.class} - #{e.message}"
        )
      end
    end
  end

  def process_hotspot_plan_expiry(tenant)
    hotspot_subscriptions = HotspotVoucher.where(account_id: tenant.id)

    hotspot_subscriptions.find_each do |subscription|
      next unless subscription.voucher.present?

      begin
        plan = tenant&.hotspot_and_dial_plan
        expired_hotspot = plan&.expiry.present? && plan.expiry <= Time.current

        if expired_hotspot
          RadCheck.find_or_create_by!(
            username: subscription.voucher,
            radiusattribute: 'Auth-Type',
            account_id: subscription.account_id,
            op: ':=',
            value: 'Reject'
          )
        else
          RadCheck.where(
            username: subscription.voucher,
            account_id: subscription.account_id,
            radiusattribute: 'Auth-Type',
            value: 'Reject'
          ).destroy_all
        end
      rescue StandardError => e
        Rails.logger.error(
          "HotspotExpirationJob: RADIUS update failed for voucher " \
          "##{subscription.id} (account ##{tenant.id}): #{e.class} - #{e.message}"
        )
      end
    end
  end

  def calculate_expiration_voucher(package, voucher_created, account_id)
    hotspot_package = HotspotPackage.find_by(name: package, account_id: account_id)
    return unless hotspot_package

    expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
      case hotspot_package.validity_period_units.downcase
      when 'days'    then Time.current + hotspot_package.validity.days
      when 'hours'   then Time.current + hotspot_package.validity.hours
      when 'minutes' then Time.current + hotspot_package.validity.minutes
      else nil
      end
    end

    if expiration_time.present?
      voucher_created.update(expiration: expiration_time)
    end

    { expiration: expiration_time }
  end

  def logout_hotspot_user(voucher, tenant)
    hotspot_package = HotspotPackage.find_by(name: voucher.package, account_id: tenant.id)
    return unless hotspot_package

    router = NasRouter.find_by(name: hotspot_package.nas_router, account_id: tenant.id)
    return unless router

    router_ip = router.ip_address
    router_username = router.username
    router_password = router.password

    # Router already timed out earlier in this same job run - don't burn another
    # SSH_CONNECT_TIMEOUT seconds retrying it for every remaining voucher.
    if @failed_routers[router_ip]
      Rails.logger.info(
        "Skipping logout for user #{voucher.voucher}: router #{router.name || router_ip} " \
        "already unreachable earlier in this run"
      )
      return
    end

    remove_command = "/ip hotspot active remove [find user=#{voucher.voucher}]"

    begin
      Net::SSH.start(
        router_ip,
        router_username,
        password: router_password,
        verify_host_key: :never,
        non_interactive: true,
        timeout: SSH_CONNECT_TIMEOUT
      ) do |ssh|
        output = ssh.exec!(remove_command)
        Rails.logger.info(
          "Successfully removed user #{voucher.voucher} from router #{router.name || router_ip}: #{output}"
        )
      end
    rescue Net::SSH::AuthenticationFailed
      Rails.logger.info("SSH authentication failed for MikroTik router #{router.name || router_ip}")
    rescue Net::SSH::ConnectionTimeout, Errno::ETIMEDOUT, Errno::EHOSTUNREACH, Errno::ECONNREFUSED => e
      @failed_routers[router_ip] = true
      Rails.logger.info(
        "Router #{router.name || router_ip} unreachable (#{e.class}), skipping remaining " \
        "logouts for this router for the rest of this run"
      )
    rescue StandardError => e
      Rails.logger.info(
        "Failed to logout user #{voucher.voucher} from router #{router.name || router_ip}: #{e.message}"
      )
    end
  end

  def send_expiration_sms(voucher, tenant)
    provider = tenant&.sms_provider_setting.present? && tenant.sms_provider_setting&.sms_provider
 message = render_expiration_message(tenant, voucher)
    case provider
    when 'Owitech Bulk SMS'
     
        # TenantWalletSenderService.send_sms(voucher.phone, message, tenant.id, current_user: nil)
        TenantPaymentSenderService.send_sms(voucher.phone, message, tenant.id, current_user: nil)
    when 'TextSms'
      send_expiration_text_sms(voucher.phone, voucher, tenant)
    when 'SMS leopard'
      send_expiration(voucher.phone, voucher, tenant)
    when 'Talk Sasa'
      send_expiration_talksasa(voucher.phone, voucher, tenant)
    else
      Rails.logger.info "No valid SMS provider configured for account #{tenant.id}"
    end
  end

  def send_expiration_talksasa(phone_number, voucher, tenant)
    formatted_phone_number = "254#{phone_number.gsub(/\A0/, '')}"

    sms_setting = tenant&.sms_setting
    api_key = sms_setting&.api_key
    sender_id = sms_setting&.sender_id

    original_message = render_expiration_message(tenant, voucher)

    uri = URI.parse("https://bulksms.talksasa.com/api/v3/sms/send")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request.body = {
      recipient: formatted_phone_number,
      sender_id: sender_id,
      type: "plain",
      message: original_message
    }.to_json

    begin
      response = http.request(request)
      Rails.logger.info "TalkSasa Response: #{response.body}"

      if response.is_a?(Net::HTTPSuccess)
        sms_data = JSON.parse(response.body)
        sms_status = sms_data['status']

        SystemAdminSm.create!(
          user: phone_number,
          message: original_message,
          status: sms_status,
          date: Time.current,
          system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Talk Sasa'
        )
        Rails.logger.info "Sent message successfully with talk sasa"
      else
        Rails.logger.info "Failed to send SMS with talk sasa: #{response.code} - #{response.body}"
      end
    rescue StandardError => e
      Rails.logger.error "TalkSasa SMS error for account #{tenant.id}: #{e.class} - #{e.message}"
    end
  end

  def send_expiration(phone_number, voucher, tenant)
    api_key = nil
    api_secret = nil
    sms_setting = tenant&.sms_setting

    if sms_setting&.sms_provider == 'SMS leopard'
      api_key = sms_setting.api_key
      api_secret = sms_setting.api_secret
    end

    original_message = render_expiration_message(tenant, voucher)
    sender_id = "SMS_TEST"
    uri = URI("https://api.smsleopard.com/v1/sms/send")
    params = {
      username: api_key,
      password: api_secret,
      message: original_message,
      destination: phone_number,
      source: sender_id
    }
    uri.query = URI.encode_www_form(params)

    begin
      response = Net::HTTP.get_response(uri)
      handle_sms_leopard_response(response, original_message, phone_number, tenant)
    rescue StandardError => e
      Rails.logger.error "SMS Leopard error for account #{tenant.id}: #{e.class} - #{e.message}"
    end
  end

  def send_expiration_text_sms(phone_number, voucher, tenant)
    api_key = nil
    partnerID = nil
    shortcode = nil
    sms_setting = tenant&.sms_setting

    if sms_setting&.sms_provider == 'TextSms'
      api_key = sms_setting.api_key
      partnerID = sms_setting.partnerID
      shortcode = sms_setting.sender_id
    end

    original_message = render_expiration_message(tenant, voucher)
    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: api_key,
      message: original_message,
      mobile: phone_number,
      partnerID: partnerID,
      shortcode: shortcode
    }
    uri.query = URI.encode_www_form(params)

    begin
      response = Net::HTTP.get_response(uri)
      handle_textsms_response(response, original_message, phone_number, tenant)
    rescue StandardError => e
      Rails.logger.error "TextSms error for account #{tenant.id}: #{e.class} - #{e.message}"
    end
  end

  def handle_textsms_response(response, message, phone_number, tenant)
    sms_recipient = phone_number
    sms_status = nil

    if response.is_a?(Net::HTTPSuccess)
      begin
        sms_data = JSON.parse(response.body)
        sms_recipient = sms_data.dig('responses', 0, 'mobile') || phone_number
        sms_status = sms_data.dig('responses', 0, 'response-description')
        Rails.logger.info "Recipient: #{sms_recipient}, Status: #{sms_status}"
      rescue JSON::ParserError => e
        Rails.logger.error "TextSms: failed to parse response body: #{e.message}"
        sms_status = 'parse_error'
      end
    else
      Rails.logger.error "Failed to send message: #{response.body}"
      sms_status = "http_error_#{response.code}"
    end

    SystemAdminSm.create!(
      user: sms_recipient,
      message: message,
      status: sms_status,
      date: Time.current,
      system_user: 'system',
      sms_provider: 'Text Sms',
      account_id: tenant.id
    )
  end

  def handle_sms_leopard_response(response, message, phone_number, tenant)
    sms_recipient = phone_number
    sms_status = nil

    if response.is_a?(Net::HTTPSuccess)
      begin
        sms_data = JSON.parse(response.body)
        sms_recipient = sms_data.dig('responses', 0, 'mobile') || phone_number
        sms_status = sms_data.dig('responses', 0, 'response-description')
        Rails.logger.info "Recipient: #{sms_recipient}, Status: #{sms_status}"
      rescue JSON::ParserError => e
        Rails.logger.error "SMS Leopard: failed to parse response body: #{e.message}"
        sms_status = 'parse_error'
      end
    else
      Rails.logger.error "Failed to send message: #{response.body}"
      sms_status = "http_error_#{response.code}"
    end

    SystemAdminSm.create!(
      user: sms_recipient,
      message: message,
      status: sms_status,
      date: Time.current,
      system_user: 'system',
      sms_provider: 'SMS leopard',
      account_id: tenant.id
    )
  end

  def render_expiration_message(tenant, voucher)
    template = HotspotSmsTemplate.find_by(account_id: tenant.id, category: 'expiration', active: true)
    data = {
      customer_phone: voucher.phone,
      voucher_code: voucher.voucher,
      plan_name: voucher.package,
      company_name: tenant.company_setting&.company_name
    }
    template ? template.render(data) : "Hello, your voucher #{voucher.voucher} is expired renew now to stay connected."
  end
end