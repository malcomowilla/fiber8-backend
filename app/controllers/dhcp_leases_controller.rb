# app/controllers/dhcp_leases_controller.rb
#
# GET /api/dhcp_leases?router=RouterName
# Fetches live DHCP leases from a NasRouter via SSH (RouterOS /ip dhcp-server lease print terse)
# Falls back to MikroTik REST API if api_username is present.
#
# NasRouter fields used:
#   ip_address  → router's IP to connect to
#   username    → SSH / REST API username
#   password    → SSH / REST API password
#   api_username, api_password → if present, REST API is used instead of SSH

class DhcpLeasesController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity
  before_action :set_time_zone

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def update_last_activity
    current_user&.update!(last_activity_active: Time.current)
  end

  def set_time_zone
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
  end

  # GET /api/dhcp_leases?router=RouterName
  def index
    router_name = params[:router].to_s.strip
    return render json: { error: 'router param required' }, status: :unprocessable_entity if router_name.blank?

    router = NasRouter.find_by(name: router_name)
    return render json: { error: "Router '#{router_name}' not found" }, status: :not_found unless router

    leases = fetch_leases(router)
    render json: leases
  rescue => e
    Rails.logger.error "DhcpLeasesController error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    render json: { error: "Failed to fetch leases: #{e.message}" }, status: :internal_server_error
  end

  private

  def fetch_leases(router)
    # Use REST API if api_username is populated, otherwise SSH with username/password
    if router.api_username.present?
      fetch_via_rest_api(router)
    elsif router.username.present?
      fetch_via_ssh(router)
    else
      raise "Router '#{router.name}' has no credentials (username is blank)"
    end
  end

  # ── MikroTik REST API (RouterOS v7+) ─────────────────────────────────────────
  # Uses: router.ip_address, router.api_username, router.api_password
  def fetch_via_rest_api(router)
    require 'net/http'
    require 'uri'
    require 'json'

    ip       = router.ip_address
    username = router.api_username
    password = router.api_password.to_s
    port     = 80   # change to 443 if HTTPS is enabled on the router

    uri = URI("http://#{ip}:#{port}/rest/ip/dhcp-server/lease")

    http              = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 8
    http.read_timeout = 12

    request = Net::HTTP::Get.new(uri)
    request.basic_auth(username, password)
    request['Content-Type'] = 'application/json'

    response = http.request(request)
    raise "MikroTik REST API returned HTTP #{response.code}: #{response.body.truncate(200)}" \
      unless response.is_a?(Net::HTTPSuccess)

    normalize_rest_leases(JSON.parse(response.body))
  end

  def normalize_rest_leases(raw)
    raw.map do |l|
      {
        address:       l['address']      || l['active-address'] || '',
        mac_address:   (l['mac-address'] || '').upcase,
        host_name:     l['host-name']    || l['comment']        || '',
        server:        l['server']       || '',
        type:          l['dynamic'] == 'true' ? 'dynamic' : 'static',
        status:        l['status']       || 'bound',
        expires_after: l['expires-after'] || '',
      }
    end.reject { |l| l[:mac_address].blank? }
  end

  # ── SSH ───────────────────────────────────────────────────────────────────────
  # Uses: router.ip_address, router.username, router.password
  # Requires gem 'net-ssh' in Gemfile
  def fetch_via_ssh(router)
    require 'net/ssh'

    ip       = router.ip_address
    username = router.username
    password = router.password.to_s
    output   = ''

    Rails.logger.info "DhcpLeasesController: SSH to #{ip} as #{username}"

    Net::SSH.start(ip, username,
      password:        password,
      auth_methods:    %w[password keyboard-interactive],
      non_interactive: true,
      timeout:         12,
      verify_host_key: :never   # MikroTik uses a self-signed host key
    ) do |ssh|
      output = ssh.exec!('/ip dhcp-server lease print terse')
    end

    Rails.logger.debug "DhcpLeasesController SSH raw output:\n#{output}"
    parse_ssh_leases(output)
  end

  # Parses both MikroTik output formats:
  #
  # terse format (key=value pairs):
  #   0 D address=172.18.8.254 mac-address=58:2B:CB:95:04:37 host-name=DESKTOP-9ECACMJ server=dhcp3
  #   1   address=10.2.0.5 mac-address=AA:BB:CC:DD:EE:FF host-name=SmartTV server=dhcp1
  #
  # columnar format (if terse not supported):
  #   Flags: D - DYNAMIC
  #   #   ADDRESS       MAC-ADDRESS        HOST-NAME    SERVER
  #   0   172.18.8.254  58:2B:CB:95:04:37  DESKTOP      dhcp3
  def parse_ssh_leases(raw_output)
    leases     = []
    in_columns = false

    raw_output.to_s.each_line do |line|
      line = line.rstrip
      next if line.blank?
      next if line.match?(/^\s*Flags:/i)

      # terse format — line contains key=value pairs
      if line.include?('=')
        is_dynamic = line.match?(/^\s*\d+\s+D\b/i)

        fields = {}
        line.scan(/([a-z][\w\-]*)=("(?:[^"]*)"|[^\s]+)/i) do |key, val|
          fields[key.downcase] = val.delete('"')
        end

        next if fields['mac-address'].blank?

        leases << {
          address:       fields['address']       || fields['active-address'] || '',
          mac_address:   fields['mac-address'].upcase,
          host_name:     fields['host-name']     || fields['comment']        || '',
          server:        fields['server']        || '',
          type:          is_dynamic ? 'dynamic' : 'static',
          status:        fields['status']        || 'bound',
          expires_after: fields['expires-after'] || '',
        }

      # columnar format — header row
      elsif line.match?(/^\s*#\s+ADDRESS/i)
        in_columns = true

      # columnar format — data rows
      elsif in_columns && line.match?(/^\s*\d+/)
        is_dynamic = line.match?(/^\s*\d+\s+D\b/i)
        cells      = line.strip.split(/\s{2,}/)
        cells.shift  # remove the row index cell ("0", "1 D", etc.)

        mac = (cells[1] || '').strip.upcase
        next if mac.blank?

        leases << {
          address:       (cells[0] || '').strip,
          mac_address:   mac,
          host_name:     (cells[2] || '').strip,
          server:        (cells[3] || '').strip,
          type:          is_dynamic ? 'dynamic' : 'static',
          status:        'bound',
          expires_after: '',
        }
      end
    end

    leases
  end
end