class AccessPointPingJob
  include Sidekiq::Job
  sidekiq_options queue: :default, lock: :until_executed, lock_timeout: 0

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        Rails.logger.info "Checking access points for tenant #{tenant.id}"

        AccessPoint.where(account_id: tenant.id).each do |ap|
          check_access_point(ap, tenant)
        end
      end
    end
  end

  private

  def check_access_point(ap, tenant)
    ip = ap.ip
    previous_status = ap.reachable

    # ✅ TCP Ping
    start_time = Time.now
    reachable = tcp_reachable?(ip)
    latency = ((Time.now - start_time) * 1000).round(2)

    # ✅ SNMP Stats (if enabled)
    snmp_data = {}
    snmp_data = fetch_snmp_data(ip, ap.snmp_community, ap.snmp_version) if ap.snmp_enabled && reachable

    # ✅ Update access point
    ap.update!(
      reachable: reachable,
      ping_latency_ms: reachable ? latency : nil,
      checked_at: Time.current,
      last_seen_at: reachable ? Time.current : ap.last_seen_at,
      uptime: snmp_data[:uptime],
      connected_clients: snmp_data[:connected_clients] || ap.connected_clients,
      firmware_version: snmp_data[:firmware_version] || ap.firmware_version
    )

    Rails.logger.info "AP #{ap.name} (#{ip}): #{reachable ? 'reachable' : 'unreachable'} #{latency}ms"

    # ✅ Send SMS notification if status changed
    if previous_status != reachable
      notify_status_change(ap, tenant, reachable)
    end

  rescue => e
    Rails.logger.error "AccessPointPingJob failed for AP #{ap.id} (#{ap.ip}): #{e.message}"
  end

  def tcp_reachable?(ip, timeout: 3)
    Timeout.timeout(timeout) do
      begin
        socket = TCPSocket.new(ip, 80)
        socket.close
        true
      rescue Errno::ECONNREFUSED
        true  # Port closed but host reachable
      rescue StandardError
        false
      end
    end
  rescue Timeout::Error
    false
  end

  # ✅ SNMP Data Fetching
  def fetch_snmp_data(ip, community = 'public', version = '2c')
    require 'snmp'
    data = {}

    SNMP::Manager.open(host: ip, community: community, version: version.to_sym) do |manager|
      # System uptime
      uptime = manager.get('1.3.6.1.2.1.1.3.0').varbind_list.first&.value
      data[:uptime] = format_uptime(uptime) if uptime

      # System description (firmware)
      desc = manager.get('1.3.6.1.2.1.1.1.0').varbind_list.first&.value
      data[:firmware_version] = desc.to_s if desc

      # Interface count (connected clients estimate)
      data[:connected_clients] = 0
    end

    data
  rescue => e
    Rails.logger.warn "SNMP failed for #{ip}: #{e.message}"
    {}
  end

  def format_uptime(timeticks)
    seconds = timeticks.to_i / 100
    days = seconds / 86400
    hours = (seconds % 86400) / 3600
    minutes = (seconds % 3600) / 60
    "#{days}d #{hours}h #{minutes}m"
  end

  def notify_status_change(ap, tenant, reachable)
    nas_setting = tenant&.nas_setting
    return unless nas_setting&.notification_when_unreachable
    phone = nas_setting.notification_phone_number
    return if phone.blank?

    message = if reachable
      "✅ Access Point '#{ap.name}' (#{ap.ip}) is back ONLINE. Location: #{ap.location || 'N/A'}"
    else
      "🔴 ALERT: Access Point '#{ap.name}' (#{ap.ip}) is OFFLINE. Location: #{ap.location || 'N/A'}. Please check immediately."
    end

    # Use your existing SMS service
    provider = tenant&.sms_provider_setting&.sms_provider
    send_sms(provider, phone, tenant, message)
  end

  def send_sms(provider, phone, tenant, message)
    case provider
    when 'Talk Sasa'
      send_talksasa(phone, tenant, message)
    when 'TextSms'
      send_textsms(phone, tenant, message)
    when 'SMS leopard'
      send_sms_leopard(phone, tenant, message)
    when 'Owitech Bulk SMS'
      TenantSmsSenderService.send_sms(phone, message, tenant.id)
    else
      Rails.logger.warn "No SMS provider for tenant #{tenant.id}"
    end
  end

  # Reuse your existing SMS methods here...
end
