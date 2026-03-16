class WireguardPeersController < ApplicationController

load_and_authorize_resource

before_action :update_last_activity
before_action :set_tenant
before_action :set_time_zone





 def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end





   def update_last_activity
if current_user
      current_user.update!(last_activity_active: Time.current)
    end
    
  end





def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
     ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
  # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
  end

  # GET /wireguard_peers or /wireguard_peers.json
  def index
    @wireguard_peers = WireguardPeer.all
    render json: @wireguard_peers
  end

  # GET /wireguard_peers/1 or /wireguard_peers/1.json
  def show
  end

  # GET /wireguard_peers/new
  def new
    @wireguard_peer = WireguardPeer.new
  end

  # GET /wireguard_peers/1/edit
  def edit
  end

  # POST /wireguard_peers or /wireguard_peers.json
  def create
  private_ip = params[:wireguard_peer][:private_ip].to_s.strip

  @wireguard_peer = WireguardPeer.new(private_ip: private_ip)

  # Validate early to avoid unnecessary system calls
  unless @wireguard_peer.valid?
    render json: @wireguard_peer.errors, status: :unprocessable_entity
    return
  end

  # Use a transaction to keep database and system state consistent
  ActiveRecord::Base.transaction do
    # Attempt to add route
    success = system('ip', 'route', 'add', private_ip, 'dev', 'wg0')

    unless success
      raise "Failed to add route for #{private_ip}"
    end

    # Save the peer
    if @wireguard_peer.save
      # Log success
      ActivityLog.create(
        action: 'create',
        ip: request.remote_ip,
        description: "Created wireguard peer for private ip #{@wireguard_peer.private_ip}",
        user_agent: request.user_agent,
        user: current_user&.username || current_user&.email || 'system',
        date: Time.current
      )
      render json: @wireguard_peer, status: :created
    else
      # This shouldn't happen because we validated, but just in case
      raise @wireguard_peer.errors.full_messages.join(', ')
    end
  end

rescue => e
  # If anything fails, rollback the transaction and try to remove the route (if added)
  # Note: The transaction automatically rolls back DB changes, but we need to clean up the route.
  # We can attempt to remove the route, but it might not have been added.
  system('ip', 'route', 'del', private_ip, 'dev', 'wg0') if private_ip.present?
  render json: { error: e.message }, status: :unprocessable_entity
end







def update
  @wireguard_peer = WireguardPeer.find(params[:id])
  old_ip = @wireguard_peer.private_ip
  new_ip = params[:wireguard_peer][:private_ip].to_s.strip

  # Build the peer object with new attributes for validation
  @wireguard_peer.assign_attributes(private_ip: new_ip)

  # Validate early to avoid unnecessary system calls
  unless @wireguard_peer.valid?
    render json: @wireguard_peer.errors, status: :unprocessable_entity
    return
  end

  # If IP hasn't changed, just update (no route changes needed)
  if old_ip == new_ip
    if @wireguard_peer.save
      log_activity('update')
      render json: @wireguard_peer, status: :ok
    else
      render json: @wireguard_peer.errors, status: :unprocessable_entity
    end
    return
  end

  # IP changed – manage routes inside a transaction
  ActiveRecord::Base.transaction do
    # 1. Remove the old route (ignore failure if it doesn't exist)
    system('ip', 'route', 'del', old_ip, 'dev', 'wg0')

    # 2. Add the new route
    unless system('ip', 'route', 'add', new_ip, 'dev', 'wg0')
      raise "Failed to add route for #{new_ip}"
    end

    # 3. Save the updated peer
    unless @wireguard_peer.save
      raise @wireguard_peer.errors.full_messages.join(', ')
    end

    # 4. Log success
    log_activity('update')
    render json: @wireguard_peer, status: :ok
  end

rescue => e
  # If anything failed, try to restore the old route and clean up
  begin
    # Attempt to remove the new route (if it was added)
    system('ip', 'route', 'del', new_ip, 'dev', 'wg0')
  rescue
    # Ignore errors during cleanup
  end

  begin
    # Restore the old route (ignore if it already exists)
    system('ip', 'route', 'add', old_ip, 'dev', 'wg0')
  rescue
    # Ignore
  end

  render json: { error: e.message }, status: :unprocessable_entity
end


def log_activity(action)
  ActivityLog.create(
    action: action,
    ip: request.remote_ip,
    description: "#{action}d wireguard peer for private ip #{@wireguard_peer.private_ip}",
    user_agent: request.user_agent,
    user: current_user&.username || current_user&.email || 'system',
    date: Time.current
  )
end



  # DELETE /wireguard_peers/1 or /wireguard_peers/1.json
  def destroy
          @wireguard_peer = WireguardPeer.find(params[:id])
ActivtyLog.create(action: 'delete', ip: request.remote_ip,
 description: "Deleted wireguard peer for private ip #{@wireguard_peer.private_ip}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
    @wireguard_peer.destroy!
`ip route del #{@wireguard_peer.private_ip} dev wg0`

     head :no_content 
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_wireguard_peer
      @wireguard_peer = WireguardPeer.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def wireguard_peer_params
      params.require(:wireguard_peer).permit(:public_key, :allowed_ips, 
      :persistent_keepalive, :private_ip)
    end
end


