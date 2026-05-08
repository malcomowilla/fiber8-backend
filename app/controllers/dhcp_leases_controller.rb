# app/controllers/dhcp_leases_controller.rb
#
# Fetches live DHCP leases from a MikroTik router and returns them as JSON.
# The router record is looked up by name within the current tenant.
#
# Route (config/routes.rb):
#   namespace :api do
#     get 'dhcp_leases', to: 'dhcp_leases#index'
#   end
#
# GET /api/dhcp_leases?router=RouterName
#
# Response:
# [
#   {
#     "address":      "172.18.8.254",
#     "mac_address":  "58:2B:CB:95:04:37",
#     "host_name":    "DESKTOP-9ECACMJ",
#     "server":       "dhcp3",
#     "type":         "dynamic",       # or "static"
#     "status":       "bound"          # MikroTik status field
#   },
#   ...
# ]

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
    Rails.logger.error "DhcpLeasesController error: #{e.message}"
    render json: { error: "Failed to fetch leases: #{e.message}" }, status: :internal_server_error
  end

  private

  # ── MikroTik REST API ────────────────────────────────────────────────────────
  # Requires MikroTik RouterOS v7+ with REST API enabled.
  # Enable on the router: /ip/service set www-ssl disabled=no  (or www for HTTP)
  #
  # The router model should expose: host (IP/hostname), api_username, api_password,
  # api_port (default 443 for HTTPS / 80 for HTTP), use_ssl (boolean).
  #
  # If you use the older MikroTik API gem (ros_api / mikrotik gem) instead of
  # the REST API, swap in that logic inside fetch_via_api below.

  def fetch_leases(router)
    # Try REST API first; fall back to SSH if configured
    if router.respond_to?(:api_username) && router.api_username.present?
      fetch_via_rest_api(router)
    elsif router.respond_to?(:ssh_username) && router.ssh_username.present?
      fetch_via_ssh(router)
    else
      raise "Router '#{router.name}' has no API or SSH credentials configured"
    end
  end

  # ── Option A: MikroTik REST API (RouterOS v7+) ───────────────────────────────
  def fetch_via_rest_api(router)
    require 'net/http'
    require 'uri'
    require 'json'

    scheme   = router.try(:use_ssl) ? 'https' : 'http'
    port     = router.try(:api_port) || (router.try(:use_ssl) ? 443 : 80)
    host     = router.host
    username = router.api_username
    password = router.api_password

    uri = URI("#{scheme}://#{host}:#{port}/rest/ip/dhcp-server/lease")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl       = (scheme == 'https')
    http.verify_mode   = OpenSSL::SSL::VERIFY_NONE   # set VERIFY_PEER in production with cert
    http.open_timeout  = 8
    http.read_timeout  = 12

    request = Net::HTTP::Get.new(uri)
    request.basic_auth(username, password)
    request['Content-Type'] = 'application/json'

    response = http.request(request)
    raise "MikroTik API returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    raw_leases = JSON.parse(response.body)
    normalize_rest_leases(raw_leases)
  end

  # Map REST API fields → our standard shape
  # REST API returns keys like: ".id", "address", "mac-address", "host-name",
  #   "server", "status", "dynamic", "expires-after", "active-address", etc.
  def normalize_rest_leases(raw)
    raw.map do |l|
      {
        address:     l['address']      || l['active-address'] || '',
        mac_address: (l['mac-address'] || '').upcase,
        host_name:   l['host-name']    || l['comment'] || '',
        server:      l['server']       || '',
        type:        l['dynamic'] == 'true' ? 'dynamic' : 'static',
        status:      l['status']       || 'bound',
        expires_after: l['expires-after'] || '',
      }
    end.reject { |l| l[:mac_address].blank? }
  end

  # ── Option B: SSH fallback ────────────────────────────────────────────────────
  # Requires the 'net-ssh' gem:  gem 'net-ssh'
  # Router model needs: host, ssh_username, ssh_password (or ssh_key_path)
  def fetch_via_ssh(router)
    require 'net/ssh'

    output = ''

    ssh_opts = {
      auth_methods:    ['password', 'keyboard-interactive'],
      password:        router.ssh_password,
      non_interactive: true,
      timeout:         10,
      # If using key auth instead:
      # keys:          [router.ssh_key_path],
      # auth_methods:  ['publickey'],
    }

    Net::SSH.start(router.host, router.ssh_username, ssh_opts) do |ssh|
      # Print lease table with terse flag for machine-readable output
      output = ssh.exec!('/ip dhcp-server lease print terse')
    end

    parse_ssh_leases(output)
  end

  # Parse MikroTik "print terse" output:
  # 0 D address=172.18.8.254 mac-address=58:2B:CB:95:04:37 host-name=DESKTOP server=dhcp3 ...
  def parse_ssh_leases(raw_output)
    leases = []

    raw_output.to_s.each_line do |line|
      line = line.strip
      next if line.blank? || line.start_with?('Flags:') || line.start_with?('Columns:') || line.start_with?('#')

      # Detect dynamic flag (D at start of flags column)
      is_dynamic = line.match?(/^\d+\s+D\b/i)

      fields = {}
      # Extract key=value pairs (values may be quoted or unquoted)
      line.scan(/(\S+)=("(?:[^"]*)"|[\S]+)/) do |key, val|
        fields[key] = val.delete('"')
      end

      next if fields['mac-address'].blank?

      leases << {
        address:     fields['address']      || fields['active-address'] || '',
        mac_address: (fields['mac-address'] || '').upcase,
        host_name:   fields['host-name']    || fields['comment']       || '',
        server:      fields['server']       || '',
        type:        is_dynamic ? 'dynamic' : 'static',
        status:      fields['status']       || 'bound',
        expires_after: fields['expires-after'] || '',
      }
    end

    leases
  end
end