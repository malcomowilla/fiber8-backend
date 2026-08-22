class RouterTroubleshootingController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :set_time_zone
  before_action :find_nas_router, only: [
    :diagnostics, :dhcp_leases, :firewall_rules, :wireguard_status, :hotspot_status, :ping, :ask
  ]

  def set_time_zone
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
  end

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # GET /router_troubleshooting
  def overview
    routers = NasRouter.where(account_id: @account.id)
    statuses = RouterStatus.where(account_id: @account.id).index_by(&:ip)

    render json: routers.map { |r|
      status = statuses[r.ip_address]
      {
        id: r.id,
        name: r.name,
        ip_address: r.ip_address,
        location: r.location,
        reachable: status&.reachable || false,
        last_checked: status&.checked_at
      }
    }
  end

  # GET /router_troubleshooting/:id/diagnostics
  def diagnostics
    resource = mikrotik_get(@nas_router, '/rest/system/resource')
    identity = mikrotik_get(@nas_router, '/rest/system/identity')
    interfaces = mikrotik_get(@nas_router, '/rest/interface')

    return render json: { error: 'Router unreachable' }, status: :service_unavailable unless resource

    cpu_load = resource['cpu-load'].to_i
    total_mem = resource['total-memory'].to_i
    free_mem  = resource['free-memory'].to_i
    mem_used_pct = total_mem.positive? ? (((total_mem - free_mem).to_f / total_mem) * 100).round : nil

    total_disk = resource['total-hdd-space'].to_i
    free_disk  = resource['free-hdd-space'].to_i
    disk_used_pct = total_disk.positive? ? (((total_disk - free_disk).to_f / total_disk) * 100).round : nil

    interface_issues = Array(interfaces).select { |i| i['running'] == 'false' || i['disabled'] == 'true' }
                                          .map { |i| { name: i['name'], running: i['running'], disabled: i['disabled'] } }

    render json: {
      identity: identity&.dig('name'),
      board: resource['board-name'],
      version: resource['version'],
      uptime: resource['uptime'],
      cpu_load_percent: cpu_load,
      memory_used_percent: mem_used_pct,
      disk_used_percent: disk_used_pct,
      interfaces_down: interface_issues,
      insights: build_insights(cpu_load, mem_used_pct, disk_used_pct, interface_issues)
    }
  end

  # GET /router_troubleshooting/:id/dhcp_leases
  def dhcp_leases
    leases = mikrotik_get(@nas_router, '/rest/ip/dhcp-server/lease')
    return render json: { error: 'Router unreachable' }, status: :service_unavailable unless leases

    render json: Array(leases).map { |l|
      {
        address: l['address'], mac_address: l['mac-address'],
        host_name: l['host-name'], status: l['status'],
        expires_after: l['expires-after']
      }
    }
  end

  # GET /router_troubleshooting/:id/firewall
  def firewall_rules
    rules = mikrotik_get(@nas_router, '/rest/ip/firewall/filter')
    return render json: { error: 'Router unreachable' }, status: :service_unavailable unless rules

    render json: Array(rules).map { |r|
      {
        chain: r['chain'], action: r['action'], comment: r['comment'],
        disabled: r['disabled'], bytes: r['bytes'], packets: r['packets']
      }
    }
  end

  # GET /router_troubleshooting/:id/wireguard
  def wireguard_status
    peer = find_wireguard_peer_for(@nas_router)

    unless peer
      return render json: { configured: false, message: "No WireGuard tunnel found for this router's IP" }
    end

    staleness_minutes = ((Time.current - peer.updated_at) / 60).round
    parsed = parse_peer_status(peer.status)

    render json: {
      configured: true,
      tunnel_ip: peer.private_ip.presence || strip_mask(peer.allowed_ips),
      connected: parsed[:connected],
      reachable: parsed[:reachable],
      endpoint: parsed[:endpoint],
      transfer: parsed[:transfer],
      since: parsed[:since],
      last_checked_from_job: true,
      last_checked_minutes_ago: staleness_minutes
    }
  end

  # POST /router_troubleshooting/:id/ping
  def ping
    reachable = tcp_reachable?(@nas_router.ip_address, 80, timeout: 2)
    render json: { reachable: reachable, checked_at: Time.current }
  end

  # POST /router_troubleshooting/:id/ask
  def ask
    diagnostics_snapshot = safe_diagnostics_snapshot

    result = RouterTroubleshootingAiService.ask(
      router: @nas_router,
      diagnostics: diagnostics_snapshot,
      question: params[:message],
      history: params[:history] || [],
      tool_executor: method(:run_diagnostic_tool)
    )

    if result[:success]
      render json: { reply: result[:reply] }
    else
      render json: {
        error: result[:error],
        fallback: true,
        snapshot: diagnostics_snapshot
      }, status: :service_unavailable
    end
  end

  # GET /router_troubleshooting/:id/hotspot
  def hotspot_status
    active = mikrotik_get(@nas_router, '/rest/ip/hotspot/active')
    return render json: { error: 'Router unreachable' }, status: :service_unavailable unless active

    render json: {
      active_user_count: Array(active).size,
      active_users: Array(active).first(25).map { |u|
        { user: u['user'], address: u['address'], uptime: u['uptime'] }
      }
    }
  end

  private

  # Dispatches read-only tool calls the AI model requests during /ask.
  # ONLY read endpoints live here. Never add a case that writes to the
  # router (config changes, user creation, firewall edits) — the AI
  # should never be able to trigger those without an explicit human
  # confirmation step in the UI, separate from this chat tool loop.
  def run_diagnostic_tool(name, _args = {})
    case name
    when 'ping_router'
      { reachable: tcp_reachable?(@nas_router.ip_address, 80, timeout: 2) }
    when 'get_dhcp_leases'
      leases = mikrotik_get(@nas_router, '/rest/ip/dhcp-server/lease')
      return { error: 'router_unreachable' } unless leases

      Array(leases).first(50).map { |l|
        { address: l['address'], mac_address: l['mac-address'], host_name: l['host-name'], status: l['status'] }
      }
    when 'get_firewall_rules'
      rules = mikrotik_get(@nas_router, '/rest/ip/firewall/filter')
      return { error: 'router_unreachable' } unless rules

      Array(rules).first(50).map { |r|
        { chain: r['chain'], action: r['action'], comment: r['comment'], disabled: r['disabled'] }
      }
    when 'get_wireguard_status'
      peer = find_wireguard_peer_for(@nas_router)
      peer ? parse_peer_status(peer.status) : { configured: false }
    when 'get_hotspot_status'
      active = mikrotik_get(@nas_router, '/rest/ip/hotspot/active')
      return { error: 'router_unreachable' } unless active

      { active_user_count: Array(active).size }
    else
      { error: "unknown_tool: #{name}" }
    end
  end

  def find_wireguard_peer_for(nas_router)
    target_ip = nas_router.ip_address
    WireguardPeer.find_by(private_ip: target_ip) ||
      WireguardPeer.all.find { |p| strip_mask(p.allowed_ips) == target_ip }
  end

  def find_nas_router
    @nas_router = NasRouter.find_by(id: params[:id], account_id: @account.id)
    render json: { error: 'Router not found' }, status: :not_found unless @nas_router
  end

  def mikrotik_get(nas, path)
    response = RestClient::Request.execute(
      method: :get,
      url: "http://#{nas.ip_address}#{path}",
      user: nas.username, password: nas.password,
      timeout: 5, open_timeout: 3
    )
    JSON.parse(response.body)
  rescue RestClient::Unauthorized
    Rails.logger.warn "mikrotik_get: auth failed for #{nas.ip_address}"
    nil
  rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    Rails.logger.warn "mikrotik_get: #{nas.ip_address} unreachable (#{e.class})"
    nil
  rescue => e
    Rails.logger.warn "mikrotik_get failed for #{nas.ip_address}: #{e.message}"
    nil
  end

  def tcp_reachable?(host, port, timeout: 2)
    Socket.tcp(host, port, connect_timeout: timeout) { true }
  rescue
    false
  end

  def build_insights(cpu, mem_pct, disk_pct, interfaces_down)
    insights = []

    if cpu >= 90
      insights << { level: 'critical', message: "CPU load is #{cpu}% — sustained load this high can drop hotspot/PPPoE sessions. Check for a runaway script/queue, or plan a hardware upgrade if this isn't a brief spike." }
    elsif cpu >= 70
      insights << { level: 'warning', message: "CPU load is elevated at #{cpu}%. Worth checking active queues, logging, and connection tracking table size." }
    end

    if mem_pct && mem_pct >= 90
      insights << { level: 'critical', message: "Memory usage is at #{mem_pct}%. Risk of instability — check for large firewall connection tables or a memory leak in a running script." }
    end

    if disk_pct && disk_pct >= 90
      insights << { level: 'warning', message: "Storage is #{disk_pct}% full. Clear old logs/backups before it affects config writes." }
    end

    if interfaces_down.any?
      names = interfaces_down.map { |i| i[:name] }.join(', ')
      insights << { level: 'warning', message: "Interface(s) down or disabled: #{names}. This could explain link flaps or unreachable clients behind them." }
    end

    insights
  end

  def safe_diagnostics_snapshot
    resource = mikrotik_get(@nas_router, '/rest/system/resource') || {}
    active_hotspot = mikrotik_get(@nas_router, '/rest/ip/hotspot/active') || []
    interfaces = mikrotik_get(@nas_router, '/rest/interface') || []
    wg_peer = find_wireguard_peer_for(@nas_router)
    wg_parsed = wg_peer ? parse_peer_status(wg_peer.status) : nil

    {
      router_name: @nas_router.name,
      ip_address: @nas_router.ip_address,
      cpu_load_percent: resource['cpu-load'],
      board: resource['board-name'],
      version: resource['version'],
      uptime: resource['uptime'],
      active_hotspot_users: Array(active_hotspot).size,
      interfaces_down: Array(interfaces).select { |i| i['running'] == 'false' }.map { |i| i['name'] },
      wireguard: wg_peer ? {
        connected: wg_parsed[:connected],
        reachable: wg_parsed[:reachable],
        since: wg_parsed[:since]
      } : { configured: false }
    }
  end

  def parse_peer_status(status_text)
    return {} if status_text.blank?
    lines = status_text.to_s.split("\n")

    {
      connected: lines.first.to_s.start_with?('Connected'),
      endpoint: lines.first.to_s[/\((.*)\)/, 1],
      reachable: lines.find { |l| l.start_with?('Reachable:') }&.split(': ', 2)&.last == 'YES',
      since: lines.find { |l| l.start_with?('Since:') }&.split(': ', 2)&.last,
      transfer: lines.find { |l| l.match?(/received/) }
    }
  end

  def strip_mask(cidr)
    cidr.to_s.split('/').first
  end
end