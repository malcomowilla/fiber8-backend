# require 'open3'
require 'concurrent'



class RouterNotificationJob
  include Sidekiq::Job
  queue_as :default
  sidekiq_options lock: :until_executed, lock_timeout: 0
  # sidekiq_options lock: :while_executing  # was: lock: :until_executed, lock_timeout: 0
  def perform
    Account.includes(:nas_setting, :sms_setting).find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        process_tenant(tenant)
      rescue => e
        Rails.logger.error "RouterNotificationJob failed for tenant #{tenant.id}: #{e.message}"
        next 
      end
    end
  end

  private




 def process_tenant(tenant)
    nas_setting = tenant.nas_setting
    return unless nas_setting&.notification_when_unreachable

    notification_phone_number = nas_setting.notification_phone_number
    return if notification_phone_number.blank?

    duration_minutes = nas_setting.unreachable_duration_minutes || 0
    routers = NasRouter.where(account_id: tenant.id).to_a
    return if routers.empty?

    results = batch_tcp_check(routers)

    routers.each do |nas_router|
      reachable = results[nas_router.id]
      check_router(nas_router, tenant, notification_phone_number, duration_minutes, reachable)
    end
  end




 def batch_tcp_check(routers, port = 8728, timeout_sec = 3)
    pool = Concurrent::FixedThreadPool.new([routers.size, 20].min)
    results = Concurrent::Hash.new

    routers.each do |nas_router|
      pool.post do
        results[nas_router.id] = tcp_reachable?(nas_router.ip_address, port, timeout_sec)
      end
    end

    pool.shutdown
    pool.wait_for_termination(timeout_sec + 5) # hard ceiling so a hung socket can't hang the job
    results
  end

  def tcp_reachable?(ip, port = 8728, timeout_sec = 3)
    Socket.tcp(ip, port, connect_timeout: timeout_sec) { true }
  rescue Errno::ECONNREFUSED
    true # host reachable, port closed → still "up"
  rescue StandardError
    false
  end

 def check_router(nas_router, tenant, phone_number, duration_minutes, reachable)
    ip_address = nas_router.ip_address
    router_name = nas_router.name
    now = Time.current

    new_status = reachable ? "reachable" : "unreachable"
    previous_status = nas_router.last_status

    if previous_status != new_status
      nas_router.update!(last_status: new_status, last_status_changed_at: now)
    end

    if new_status == "unreachable"
      minutes_unreachable = (now - (nas_router.last_status_changed_at || now)) / 60.0
      already_notified = nas_router.last_notification_sent_at.present? &&
                          nas_router.last_notification_sent_at >= nas_router.last_status_changed_at

      if minutes_unreachable >= duration_minutes && !already_notified
        send_notification_sms_unreachable(phone_number, tenant, router_name, ip_address)
        nas_router.update!(last_notification_sent_at: now)
      end
    elsif new_status == "reachable" && previous_status == "unreachable"
      if nas_router.last_notification_sent_at.present? &&
         nas_router.last_notification_sent_at >= (nas_router.last_status_changed_at - 1.hour)
        send_notification_sms_reachable(phone_number, tenant, router_name, ip_address)
        nas_router.update!(last_notification_sent_at: now)
      end
    end
  end



  def tcp_reachable?(ip, port = 8728, timeout_sec = 3)
    Timeout.timeout(timeout_sec) do
      begin
        socket = TCPSocket.new(ip, port)
        socket.close
        true
      rescue Errno::ECONNREFUSED
        true  # Host reachable but port closed → still reachable
      rescue StandardError
        false
      end
    end
  rescue Timeout::Error
    false
  end

  # ═══════════════════════════════════════════════════════════════
  # SMS DISPATCHER
  # ═══════════════════════════════════════════════════════════════

  def send_notification_sms_unreachable(phone_number, tenant, router_name, ip_address)
    provider = sms_provider_for(tenant)
    message = "ALERT: Your router '#{router_name}' (#{ip_address}) is UNREACHABLE. Please check your network."

    send_sms(provider, phone_number, tenant, message)
  end

  def send_notification_sms_reachable(phone_number, tenant, router_name, ip_address)
    provider = sms_provider_for(tenant)
    message = "INFO: Your router '#{router_name}' (#{ip_address}) is back ONLINE."

    send_sms(provider, phone_number, tenant, message)
  end

  # ═══════════════════════════════════════════════════════════════
  # GET SMS PROVIDER FOR TENANT
  # ═══════════════════════════════════════════════════════════════

  def sms_provider_for(tenant)
    tenant&.sms_provider_setting&.sms_provider
  end

  # ═══════════════════════════════════════════════════════════════
  # UNIFIED SMS SENDER
  # ═══════════════════════════════════════════════════════════════

  def send_sms(provider, phone_number, tenant, message)
    case provider
     when 'Owitech Bulk SMS'
    TenantSidekiqService.send_sms(phone_number, message, tenant.id)
    when 'TextSms'
      send_text_sms(phone_number, tenant, message)
    when 'SMS leopard'
      send_sms_leopard(phone_number, tenant, message)
    when 'Talk Sasa'
      send_talksasa_sms(phone_number, tenant, message)
    else
      Rails.logger.warn "No valid SMS provider configured for tenant #{tenant.id}"
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # TALKSASA
  # ═══════════════════════════════════════════════════════════════

  def send_talksasa_sms(phone_number, tenant, message)
    # ✅ FIX: Use tenant's SMS setting, not any account's
    sms_setting = tenant.sms_setting
    unless sms_setting&.sms_provider == 'Talk Sasa'
      Rails.logger.warn "TalkSasa not configured for tenant #{tenant.id}"
      return
    end

    api_key = sms_setting.api_key
    sender_id = sms_setting.sender_id
    formatted_phone = "254#{phone_number.to_s.gsub(/\A0/, '')}"

    uri = URI.parse("https://bulksms.talksasa.com/api/v3/sms/send")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request.body = {
      recipient: formatted_phone,
      sender_id: sender_id,
      type: "plain",
      message: message
    }.to_json

    response = http.request(request)
    Rails.logger.info "TalkSasa Response: #{response.body}"

    if response.is_a?(Net::HTTPSuccess)
      sms_data = JSON.parse(response.body) rescue {}
      log_sms(tenant, phone_number, message, sms_data['status'] || 'sent', 'Talk Sasa')
    else
      Rails.logger.error "TalkSasa failed: #{response.code} - #{response.body}"
      log_sms(tenant, phone_number, message, 'failed', 'Talk Sasa')
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # SMS LEOPARD
  # ═══════════════════════════════════════════════════════════════

  def send_sms_leopard(phone_number, tenant, message)
    sms_setting = tenant.sms_setting
    unless sms_setting&.sms_provider == 'SMS leopard'
      Rails.logger.warn "SMS Leopard not configured for tenant #{tenant.id}"
      return
    end

    api_key = sms_setting.api_key
    api_secret = sms_setting.api_secret

    uri = URI("https://api.smsleopard.com/v1/sms/send")
    params = {
      username: api_key,
      password: api_secret,
      message: message,
      destination: phone_number,
      source: "SMS_TEST"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    handle_leopard_response(response, message, phone_number, tenant)
  end

  # ═══════════════════════════════════════════════════════════════
  # TEXT SMS
  # ═══════════════════════════════════════════════════════════════

  def send_text_sms(phone_number, tenant, message)
    sms_setting = tenant.sms_setting
    unless sms_setting&.sms_provider == 'TextSms'
      Rails.logger.warn "TextSms not configured for tenant #{tenant.id}"
      return
    end

    api_key = sms_setting.api_key
    partner_id = sms_setting.partnerID
    shortcode = sms_setting.sender_id

    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: api_key,
      message: message,
      mobile: phone_number,
      partnerID: partner_id,
      shortcode: shortcode
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    handle_textsms_response(response, message, phone_number, tenant)
  end

  # ═══════════════════════════════════════════════════════════════
  # RESPONSE HANDLERS
  # ═══════════════════════════════════════════════════════════════

  def handle_leopard_response(response, message, phone_number, tenant)
    if response.is_a?(Net::HTTPSuccess)
      sms_data = JSON.parse(response.body) rescue {}
      recipient = sms_data.dig('responses', 0, 'mobile') || phone_number
      status = sms_data.dig('responses', 0, 'response-description') || 'sent'
      Rails.logger.info "SMS Leopard sent to #{recipient}: #{status}"
      log_sms(tenant, recipient, message, status, 'SMS leopard')
    else
      Rails.logger.error "SMS Leopard failed: #{response.code} - #{response.body}"
      log_sms(tenant, phone_number, message, 'failed', 'SMS leopard')
    end
  end

  def handle_textsms_response(response, message, phone_number, tenant)
    if response.is_a?(Net::HTTPSuccess)
      sms_data = JSON.parse(response.body) rescue {}
      recipient = sms_data.dig('responses', 0, 'mobile') || phone_number
      status = sms_data.dig('responses', 0, 'response-description') || 'sent'
      Rails.logger.info "TextSMS sent to #{recipient}: #{status}"
      log_sms(tenant, recipient, message, status, 'Text SMS')
    else
      Rails.logger.error "TextSMS failed: #{response.code} - #{response.body}"
      log_sms(tenant, phone_number, message, 'failed', 'Text SMS')
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # LOG SMS TO DB
  # ═══════════════════════════════════════════════════════════════

  def log_sms(tenant, phone_number, message, status, provider)
    SystemAdminSm.create!(
      user: phone_number,
      message: message,
      status: status,
      date: Time.current.strftime("%B %d, %Y at %I:%M %p"),
      system_user: 'system',
      account_id: tenant.id,
      sms_provider: provider
    )
  rescue => e
    Rails.logger.error "Failed to log SMS: #{e.message}"
  end
end