# class WireguardPeersController < ApplicationController

#   load_and_authorize_resource 

#   set_current_tenant_through_filter

#   before_action :update_last_activity
#   before_action :set_tenant
#   before_action :set_time_zone





#  def set_time_zone
#   Rails.logger.info "Setting time zone"
#   Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
#     Rails.logger.info "Setting time zone #{Time.zone}"

# end





#    def update_last_activity
# if current_user
#       current_user.update!(last_activity_active: Time.current)
#     end
    
#   end





# def set_tenant
#     host = request.headers['X-Subdomain']
#     @account = Account.find_by(subdomain: host)
#      ActsAsTenant.current_tenant = @account
#     EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
#     # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
#   # set_current_tenant(@account)
#   rescue ActiveRecord::RecordNotFound
#     render json: { error: 'Invalid tenant' }, status: :not_found
  
#   end

#   # GET /wireguard_peers or /wireguard_peers.json
#   def index
#     @wireguard_peers = WireguardPeer.all
#     render json: @wireguard_peers
#   end

#   # GET /wireguard_peers/1 or /wireguard_peers/1.json
#   def show
#   end

#   # GET /wireguard_peers/new
#   def new
#     @wireguard_peer = WireguardPeer.new
#   end

#   # GET /wireguard_peers/1/edit
#   def edit
#   end

#   # POST /wireguard_peers or /wireguard_peers.json
#   def create

#     @wireguard_peer = WireguardPeer.new(
#       private_ip:  "#{params[:wireguard_peer][:private_ip]}",

#     )
# `ip route add #{params[:wireguard_peer][:private_ip]} dev wg0`
#       if @wireguard_peer.save
#         render json: @wireguard_peer, status: :created   
#         ActivtyLog.create(action: 'create', ip: request.remote_ip,
#  description: "Created wireguard peer for private ip #{@wireguard_peer.private_ip}",
#           user_agent: request.user_agent, user: current_user.username || current_user.email,
#            date: Time.current)
#       else
#          render json: @wireguard_peer.errors, status: :unprocessable_entity 
      
#     end
#   end


#   def testing
#     render json: { message: 'testing' }, status: :ok
    
#   end



#   # PATCH/PUT /wireguard_peers/1 or /wireguard_peers/1.json
#  def update
#   @wireguard_peer = WireguardPeer.find(params[:id])
#   old_ip = @wireguard_peer.private_ip

#   # 1. Parse and clean the incoming IP parameter
#   raw_ips = params[:wireguard_peer][:private_ip].to_s
#   ip_list = raw_ips.split(/[,\s]+/)          # split on commas or whitespace
#                  .reject(&:blank?)           # remove empty strings
#                  .map(&:strip)                # trim each element

#   # 2. Validate we have exactly one IP
#   if ip_list.empty?
#     render json: { error: 'Private IP cannot be blank' }, status: :unprocessable_entity
#     return
#   end

#   if ip_list.size > 1
#     render json: { error: 'Only one private IP allowed when updating a single peer' }, status: :unprocessable_entity
#     return
#   end

#   new_ip = ip_list.first

#   # 3. Assign and validate (model validation will check IP format)
#   @wireguard_peer.assign_attributes(private_ip: new_ip)

#   unless @wireguard_peer.valid?
#     render json: @wireguard_peer.errors, status: :unprocessable_entity
#     return
#   end

#   # 4. If IP unchanged, just save and log
#   if old_ip == new_ip
#     if @wireguard_peer.save
#       log_activity('update')
#       render json: @wireguard_peer, status: :ok
#     else
#       render json: @wireguard_peer.errors, status: :unprocessable_entity
#     end
#     return
#   end

#   # 5. IP changed – update routes inside a transaction
#   ActiveRecord::Base.transaction do
#     # Remove old route (ignore if it doesn't exist)
#     system('ip', 'route', 'del', old_ip, 'dev', 'wg0') if old_ip.present?

#     # Add new route
#     unless system('ip', 'route', 'add', new_ip, 'dev', 'wg0')
#       raise "Failed to add route for #{new_ip}"
#     end

#     # Save the peer
#     unless @wireguard_peer.save
#       raise @wireguard_peer.errors.full_messages.join(', ')
#     end

#     log_activity('update')
#     render json: @wireguard_peer, status: :ok
#   end

# rescue => e
#   # 6. Clean up if something went wrong
#   begin
#     system('ip', 'route', 'del', new_ip, 'dev', 'wg0' ) if new_ip.present?
#   rescue
#     # ignore
#   end

#   begin
#     system('ip', 'route', 'add', old_ip, 'dev', 'wg0') if old_ip.present?
#   rescue
#     # ignore
#   end

#   render json: { error: e.message }, status: :unprocessable_entity
# end







# # ActivtyLog.create(action: 'update', ip: request.remote_ip,
# #  description: "Updated wireguard peer for private ip #{@wireguard_peer.private_ip}",
# #           user_agent: request.user_agent, user: current_user.username || current_user.email,
# #            date: Time.current)


#   # DELETE /wireguard_peers/1 or /wireguard_peers/1.json
#   def destroy
#           @wireguard_peer = WireguardPeer.find(params[:id])
# ActivtyLog.create(action: 'delete', ip: request.remote_ip,
#  description: "Deleted wireguard peer for private ip #{@wireguard_peer.private_ip}",
#           user_agent: request.user_agent, user: current_user.username || current_user.email,
#            date: Time.current)
#     @wireguard_peer.destroy!
# `ip route del #{@wireguard_peer.private_ip} dev wg0`

#      head :no_content 
    
#   end

#   private

# def log_activity(action)
#   ActivtyLog.create(
#     action: action,
#     ip: request.remote_ip,
#     description: "#{action}d wireguard peer for private ip #{@wireguard_peer.private_ip}",
#     user_agent: request.user_agent,
#     user: current_user&.username || current_user&.email || 'system',
#     date: Time.current
#   )
# end

#     # Use callbacks to share common setup or constraints between actions.
#     def set_wireguard_peer
#       @wireguard_peer = WireguardPeer.find_by(id:params[:id])
#     end

#     # Only allow a list of trusted parameters through.
#     def wireguard_peer_params
#       params.require(:wireguard_peer).permit(:public_key, :allowed_ips, 
#       :persistent_keepalive, :private_ip)
#     end
# end

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
  #   ONE WireGuard IP
  #
  # allowed_ips:
  #   MANY networks
  #
  # Example:
  #
  # private_ip = 10.2.0.154
  #
  # allowed_ips =
  #   10.5.0.0/16
  #   172.18.8.0/24
  #   192.168.20.0/24
  #   192.168.23.0/24
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
      params_data.merge(
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
  # Supports changing:
  #
  # - private_ip
  # - allowed_ips
  #
  # Example old networks:
  #
  #   10.5.0.0/16
  #   172.18.8.0/24
  #
  # New networks:
  #
  #   10.5.0.0/16
  #   172.18.8.0/24
  #   192.168.20.0/24
  #
  # Only 192.168.20.0/24 is added.
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
  #
  # Example:
  #
  #   10.2.0.154
  #
  # Accepted:
  #   10.2.0.154
  #
  # Rejected:
  #   10.2.0.154/24
  #   10.2.0.154,10.2.0.155
  #   10.5.0.0/16
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
  # Accepts:
  #
  #   10.5.0.0/16
  #
  # or:
  #
  #   10.5.0.0/16,172.18.8.0/24
  #
  # or:
  #
  #   10.5.0.0/16
  #   172.18.8.0/24
  #
  # or:
  #
  #   10.5.0.0/16 172.18.8.0/24
  #
  # Returns:
  #
  #   [
  #     "10.5.0.0/16",
  #     "172.18.8.0/24"
  #   ]
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
  # ---------------------------------------------------------------------------

  def wireguard_peer_params
    params.require(:wireguard_peer).permit(
      :public_key,
      :allowed_ips,
      :persistent_keepalive,
      :private_ip
    )
  end
end
