require "ipaddr"

class WireguardPeersController < ApplicationController
  load_and_authorize_resource
  set_current_tenant_through_filter

  before_action :update_last_activity
  before_action :set_tenant
  before_action :set_time_zone

  # ---------------------------------------------------------------------------
  # Pool of tunnel addresses auto-assigned as WireGuard peer IPs.
  # These are shared across ALL tenants (one physical WireGuard interface),
  # so uniqueness is checked tenant-wide, not per-tenant.
  # Override with WIREGUARD_PEER_IP_POOL if 10.2.0.0/24 isn't right.
  # ---------------------------------------------------------------------------
  PEER_IP_POOL = ENV.fetch("WIREGUARD_PEER_IP_POOL", "10.2.0.0/24")

  # ---------------------------------------------------------------------------
  # Before actions
  # ---------------------------------------------------------------------------

  def set_time_zone
    Rails.logger.info "Setting time zone"

    Time.zone =
      GeneralSetting.first&.timezone ||
      Rails.application.config.time_zone

    Rails.logger.info "Setting time zone #{Time.zone}"
  end

  def update_last_activity
    current_user&.update!(last_activity_active: Time.current)
  end

  def set_tenant
    host = request.headers["X-Subdomain"]

    @account = Account.find_by(subdomain: host)

    unless @account
      render json: { error: "Invalid tenant" },
             status: :not_found
      return
    end

    ActsAsTenant.current_tenant = @account

    EmailConfiguration.configure(
      @account,
      ENV["SYSTEM_ADMIN_EMAIL"]
    )
  end

  # ---------------------------------------------------------------------------
  # GET /wireguard_peers
  # ---------------------------------------------------------------------------

  def index
    @wireguard_peers = WireguardPeer.all

    render json: @wireguard_peers
  end

  # ---------------------------------------------------------------------------
  # GET /wireguard_peers/:id
  # ---------------------------------------------------------------------------

  def show
    render json: @wireguard_peer
  end

  # ---------------------------------------------------------------------------
  # GET /wireguard_peers/new
  # ---------------------------------------------------------------------------

  def new
    @wireguard_peer = WireguardPeer.new

    render json: @wireguard_peer
  end

  # ---------------------------------------------------------------------------
  # GET /wireguard_peers/:id/edit
  # ---------------------------------------------------------------------------

  def edit
    render json: @wireguard_peer
  end

  # ---------------------------------------------------------------------------
  # POST /wireguard_peers
  #
  # The admin only supplies allowed_ips (the private network(s) that should
  # become reachable through WireGuard). private_ip (the peer's own tunnel
  # address) is NEVER accepted from the client — it is auto-assigned here.
  #
  # allowed_ips:
  #   MANY networks. Accepted as an array:
  #     ["10.5.0.0/16", "172.18.8.0/24"]
  #   or as a comma/newline separated string:
  #     "10.5.0.0/16,172.18.8.0/24"
  # ---------------------------------------------------------------------------

  
  # ---------------------------------------------------------------------------
  # GET /wireguard_peers/testing
  # ---------------------------------------------------------------------------


def create
  params_data = wireguard_peer_params

  begin
    private_networks = clean_allowed_ips(params_data[:private_ip])
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
    return
  end

  peer_ip = assign_peer_ip!

  if peer_ip.blank?
    render json: { error: "No available WireGuard peer IPs left in #{PEER_IP_POOL}" },
           status: :unprocessable_entity
    return
  end

  @wireguard_peer = WireguardPeer.new(
    params_data.except(:private_ip).merge(
      allowed_ips: peer_ip,
      private_ip: private_networks.join(",")
    )
  )

  unless @wireguard_peer.valid?
    render json: @wireguard_peer.errors, status: :unprocessable_entity
    return
  end

  added_routes = []

  begin
    @wireguard_peer.save!

    # Only the LAN network(s) need a route — the peer's own tunnel
    # address is already on-link via wg0's subnet route.
    private_networks.each do |network|
      add_route(network)
      added_routes << network
    end

    log_activity("create")
    render json: @wireguard_peer, status: :created
  rescue => e
    Rails.logger.error("Failed to create WireGuard peer: #{e.class}: #{e.message}")
    added_routes.each { |n| delete_route(n) rescue nil }
    @wireguard_peer.destroy if @wireguard_peer.persisted?
    render json: { error: "Failed to configure WireGuard routes", details: e.message },
           status: :unprocessable_entity
  end
end



  def testing
    render json: {
      message: "testing"
    }, status: :ok
  end

  # ---------------------------------------------------------------------------
  # PATCH/PUT /wireguard_peers/:id
  #
  # private_ip is immutable once assigned — only allowed_ips can be edited.
  # Diffs old vs new allowed_ips and only touches routes that actually
  # changed (adds new networks, removes dropped ones).
  # ---------------------------------------------------------------------------

  def update
  @wireguard_peer = WireguardPeer.find(params[:id])

  old_networks = clean_allowed_ips(@wireguard_peer.private_ip)

  begin
    new_networks = clean_allowed_ips(params.dig(:wireguard_peer, :private_ip))
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
    return
  end

  routes_to_remove = old_networks - new_networks
  routes_to_add = new_networks - old_networks

  removed_routes = []
  added_routes = []

  begin
    routes_to_remove.each { |n| delete_route(n); removed_routes << n }
    routes_to_add.each { |n| add_route(n); added_routes << n }

    @wireguard_peer.private_ip = new_networks.join(",")
    raise @wireguard_peer.errors.full_messages.join(", ") unless @wireguard_peer.save

    log_activity("update")
    render json: @wireguard_peer, status: :ok
  rescue => e
    Rails.logger.error("WireGuard peer update failed: #{e.class}: #{e.message}")
    added_routes.each { |n| delete_route(n) rescue nil }
    removed_routes.each { |n| add_route(n) rescue nil }
    @wireguard_peer.private_ip = old_networks.join(",")
    render json: { error: "Failed to update WireGuard routes", details: e.message },
           status: :unprocessable_entity
  end
end

  # ---------------------------------------------------------------------------
  # DELETE /wireguard_peers/:id
  # ---------------------------------------------------------------------------

  def destroy
    @wireguard_peer = WireguardPeer.find(params[:id])
networks = clean_allowed_ips(
  @wireguard_peer.private_ip
)

    begin
      # Remove every route belonging to this peer
      networks.each do |network|
        begin
          delete_route(network)
        rescue => e
          Rails.logger.error(
            "Failed to delete WireGuard route #{network}: " \
            "#{e.message}"
          )
        end
      end

      log_activity("delete")

      @wireguard_peer.destroy!

      head :no_content

    rescue => e
      Rails.logger.error(
        "Failed to destroy WireGuard peer: " \
        "#{e.class}: #{e.message}"
      )

      render json: {
        error: "Failed to delete WireGuard peer",
        details: e.message
      }, status: :unprocessable_entity
    end
  end

  # ===========================================================================
  # PRIVATE
  # ===========================================================================

  private

  # ---------------------------------------------------------------------------
  # Auto-assign the next free tunnel IP from PEER_IP_POOL.
  #
  # Uniqueness is checked ACROSS ALL TENANTS (ActsAsTenant.without_tenant)
  # because every peer shares the same physical WireGuard interface/routes.
  # Returns nil if the pool is exhausted.
  # 
  #
  #---------------------------------------------------------------------------





def assign_peer_ip!
  pool = IPAddr.new(PEER_IP_POOL)
  range = pool.to_range.to_a
  usable = range.length > 2 ? range[1..-2] : range

  used_ips = ActsAsTenant.without_tenant do
    WireguardPeer.pluck(:allowed_ips).compact.to_set
  end

  usable.each do |addr|
    ip = "#{addr}/32"
    return ip unless used_ips.include?(ip)
  end

  nil
end







  def assign_private_ip!
    pool = IPAddr.new(PEER_IP_POOL)
    range = pool.to_range.to_a

    # Skip network + broadcast addresses for normal subnets.
    usable = range.length > 2 ? range[1..-2] : range

    used_ips = ActsAsTenant.without_tenant do
      WireguardPeer.pluck(:private_ip).compact.to_set
    end

    usable.each do |addr|
      ip = addr.to_s
      return ip unless used_ips.include?(ip)
    end

    nil
  end

  # ---------------------------------------------------------------------------
  # Clean and validate MULTIPLE IPv4 networks
  #
  # Accepts an Array, or a String separated by commas/newlines/spaces.
  # ---------------------------------------------------------------------------

  def clean_allowed_ips(value)
    ips =
      case value
      when Array
        value
      else
        value.to_s.split(/[,\s]+/)
      end

    ips =
      ips
      .map(&:to_s)
      .map(&:strip)
      .reject(&:blank?)
      .uniq

    return [] if ips.empty?

    ips.map do |network|
      validate_ipv4_network!(network)
    end
  end

  # ---------------------------------------------------------------------------
  # Validate one CIDR network
  # ---------------------------------------------------------------------------

  def validate_ipv4_network!(network)
    begin
      addr = IPAddr.new(network)

      unless addr.ipv4?
        raise ArgumentError,
              "IPv4 networks only: #{network}"
      end

      unless network.include?("/")
        raise ArgumentError,
              "CIDR prefix required: #{network}"
      end

      # Make sure prefix is actually present and valid
      prefix = network.split("/").last.to_i

      unless prefix.between?(0, 32)
        raise ArgumentError,
              "Invalid CIDR prefix: #{network}"
      end

      # Make sure this is actually a network address
      # rather than something like 10.5.50.10/24
      normalized =
        IPAddr.new(
          "#{addr}/#{prefix}"
        ).to_range.first

      network_address =
        IPAddr.new(network).mask(prefix)

      unless normalized == network_address
        raise ArgumentError,
              "Not a valid network address: #{network}"
      end

      network

    rescue IPAddr::InvalidAddressError
      raise ArgumentError,
            "Invalid IPv4 network: #{network}"
    end
  end

  # ---------------------------------------------------------------------------
  # Add a Linux route
  # ---------------------------------------------------------------------------

  def add_route(network)
    run_route_command("add", network)
  end

  # ---------------------------------------------------------------------------
  # Delete a Linux route
  # ---------------------------------------------------------------------------

  def delete_route(network)
    run_route_command("del", network)
  end

  # ---------------------------------------------------------------------------
  # Execute the controlled WireGuard route helper
  #
  # IMPORTANT:
  # We pass arguments as an array instead of constructing a shell command.
  # ---------------------------------------------------------------------------

  def run_route_command(action, network)
  address = validate_ipv4_network!(network)

  command = ["sudo", "/usr/local/sbin/wireguard-route", action, address]
  Rails.logger.info("Executing WireGuard route command: #{command.join(' ')}")

  stdout, stderr, status = Open3.capture3(*command)

  unless status.success?
    raise "wireguard-route #{action} #{address} failed: #{stderr.presence || stdout}"
  end

  true
end

  # ---------------------------------------------------------------------------
  # Activity logging
  # ---------------------------------------------------------------------------

  def log_activity(action)
    ActivtyLog.create(
      action: action,
      ip: request.remote_ip,
      description:
        "#{action}d WireGuard peer " \
        "for private ip #{@wireguard_peer.private_ip} " \
        "with networks #{@wireguard_peer.allowed_ips}",
      user_agent: request.user_agent,
      user:
        current_user&.username ||
        current_user&.email ||
        "system",
      date: Time.current
    )
  end

  # ---------------------------------------------------------------------------
  # Strong parameters
  #
  # private_ip is intentionally NOT permitted — it is server-assigned only.
  # allowed_ips is permitted BOTH as a scalar string ("10.5.0.0/16,...")
  # and as an array (["10.5.0.0/16", ...]).
  # ---------------------------------------------------------------------------

  def wireguard_peer_params
  params.require(:wireguard_peer).permit(
    :public_key,
    :private_ip,
    :persistent_keepalive,
    private_ip: []
  )
end

end