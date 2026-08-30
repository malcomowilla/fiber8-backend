	require "ipaddr"

class WireguardPeersController < ApplicationController
  load_and_authorize_resource
  set_current_tenant_through_filter

  before_action :update_last_activity
  before_action :set_tenant
  before_action :set_time_zone

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
  # private_ip:
  #   ONE WireGuard peer IP, e.g. "10.2.0.154"
  #
  # allowed_ips:
  #   MANY networks. Accepted as an array:
  #     ["10.5.0.0/16", "172.18.8.0/24"]
  #   or as a comma/newline separated string:
  #     "10.5.0.0/16,172.18.8.0/24"
  # ---------------------------------------------------------------------------

  def create
    params_data = wireguard_peer_params

    private_ip = clean_private_ip(
      params_data[:private_ip]
    )

    if private_ip.blank?
      render json: {
        error: "Private IP cannot be blank or invalid"
      }, status: :unprocessable_entity

      return
    end

    begin
      allowed_ips = clean_allowed_ips(
        params_data[:allowed_ips]
      )

    rescue ArgumentError => e
      render json: {
        error: e.message
      }, status: :unprocessable_entity

      return
    end

    @wireguard_peer = WireguardPeer.new(
      params_data.except(:allowed_ips).merge(
        private_ip: private_ip,
        allowed_ips: allowed_ips.join(",")
      )
    )

    unless @wireguard_peer.valid?
      render json: @wireguard_peer.errors,
             status: :unprocessable_entity

      return
    end

    added_routes = []

    begin
      # Save peer first
      @wireguard_peer.save!

      # Add every network route
      allowed_ips.each do |network|
        add_route(network)
        added_routes << network
      end

      log_activity("create")

      render json: @wireguard_peer,
             status: :created

    rescue => e
      Rails.logger.error(
        "Failed to create WireGuard peer: " \
        "#{e.class}: #{e.message}"
      )

      # Remove any routes that were successfully added
      added_routes.each do |network|
        begin
          delete_route(network)
        rescue => route_error
          Rails.logger.error(
            "Failed to rollback route #{network}: " \
            "#{route_error.message}"
          )
        end
      end

      # Remove database record
      begin
        @wireguard_peer.destroy if @wireguard_peer.persisted?
      rescue => destroy_error
        Rails.logger.error(
          "Failed to rollback WireGuard peer: " \
          "#{destroy_error.message}"
        )
      end

      render json: {
        error: "Failed to configure WireGuard routes",
        details: e.message
      }, status: :unprocessable_entity
    end
  end

  # ---------------------------------------------------------------------------
  # GET /wireguard_peers/testing
  # ---------------------------------------------------------------------------

  def testing
    render json: {
      message: "testing"
    }, status: :ok
  end

  # ---------------------------------------------------------------------------
  # PATCH/PUT /wireguard_peers/:id
  #
  # Diffs old vs new allowed_ips and only touches routes that actually
  # changed (adds new networks, removes dropped ones).
  # ---------------------------------------------------------------------------

  def update
    @wireguard_peer = WireguardPeer.find(params[:id])

    old_private_ip = @wireguard_peer.private_ip

    old_allowed_ips = clean_allowed_ips(
      @wireguard_peer.allowed_ips
    )

    new_private_ip = clean_private_ip(
      params.dig(:wireguard_peer, :private_ip)
    )

    if new_private_ip.blank?
      render json: {
        error: "Private IP cannot be blank or invalid"
      }, status: :unprocessable_entity

      return
    end

    begin
      new_allowed_ips = clean_allowed_ips(
        params.dig(:wireguard_peer, :allowed_ips)
      )

    rescue ArgumentError => e
      render json: {
        error: e.message
      }, status: :unprocessable_entity

      return
    end

    # Networks that need to be removed
    routes_to_remove =
      old_allowed_ips - new_allowed_ips

    # Networks that need to be added
    routes_to_add =
      new_allowed_ips - old_allowed_ips

    removed_routes = []
    added_routes = []

    begin
      # ---------------------------------------------------------
      # Remove networks no longer assigned to this peer
      # ---------------------------------------------------------

      routes_to_remove.each do |network|
        delete_route(network)
        removed_routes << network
      end

      # ---------------------------------------------------------
      # Add newly assigned networks
      # ---------------------------------------------------------

      routes_to_add.each do |network|
        add_route(network)
        added_routes << network
      end

      # ---------------------------------------------------------
      # Update database
      # ---------------------------------------------------------

      @wireguard_peer.assign_attributes(
        private_ip: new_private_ip,
        allowed_ips: new_allowed_ips.join(",")
      )

      unless @wireguard_peer.save
        raise @wireguard_peer.errors.full_messages.join(", ")
      end

      log_activity("update")

      render json: @wireguard_peer,
             status: :ok

    rescue => e
      Rails.logger.error(
        "WireGuard peer update failed: " \
        "#{e.class}: #{e.message}"
      )

      # ---------------------------------------------------------
      # Rollback newly added routes
      # ---------------------------------------------------------

      added_routes.each do |network|
        begin
          delete_route(network)
        rescue => rollback_error
          Rails.logger.error(
            "Failed to rollback added route #{network}: " \
            "#{rollback_error.message}"
          )
        end
      end

      # ---------------------------------------------------------
      # Restore routes that were removed
      # ---------------------------------------------------------

      removed_routes.each do |network|
        begin
          add_route(network)
        rescue => rollback_error
          Rails.logger.error(
            "Failed to restore removed route #{network}: " \
            "#{rollback_error.message}"
          )
        end
      end

      # Restore object attributes
      @wireguard_peer.private_ip = old_private_ip
      @wireguard_peer.allowed_ips =
        old_allowed_ips.join(",")

      render json: {
        error: "Failed to update WireGuard routes",
        details: e.message
      }, status: :unprocessable_entity
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /wireguard_peers/:id
  # ---------------------------------------------------------------------------

  def destroy
    @wireguard_peer = WireguardPeer.find(params[:id])

    networks = clean_allowed_ips(
      @wireguard_peer.allowed_ips
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
  # Clean and validate ONE WireGuard peer IP
  # ---------------------------------------------------------------------------

  def clean_private_ip(value)
    ip = value.to_s.strip

    return nil if ip.blank?

    # private_ip must be one IP, not a list
    return nil if ip.match?(/[,\s]/)

    # CIDR is not allowed here
    return nil if ip.include?("/")

    begin
      addr = IPAddr.new(ip)

      return nil unless addr.ipv4?

      ip

    rescue IPAddr::InvalidAddressError
      nil
    end
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

    command = [
      "sudo",
      "/usr/local/sbin/wireguard-route",
      action,
      address
    ]

    Rails.logger.info(
      "Executing WireGuard route command: #{command.join(' ')}"
    )

    success = system(*command)

    unless success
      raise(
        "WireGuard route command failed for #{action} #{address}"
      )
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
  # allowed_ips is permitted BOTH as a scalar string ("10.5.0.0/16,...")
  # and as an array (["10.5.0.0/16", ...]) so the array the frontend now
  # sends actually survives strong-params filtering.
  # ---------------------------------------------------------------------------

  def wireguard_peer_params
    params.require(:wireguard_peer).permit(
      :public_key,
      :allowed_ips,
      :persistent_keepalive,
      :private_ip,
      allowed_ips: []
    )
  end
end