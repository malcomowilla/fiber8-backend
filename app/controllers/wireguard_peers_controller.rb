class WireguardPeersController < ApplicationController

load_and_authorize_resource

before_action :update_last_activity
before_action :set_tenant
before_action :set_time_zone





 def set_time_zone
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone

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

    @wireguard_peer = WireguardPeer.new(
      private_ip:  "#{params[:wireguard_peer][:private_ip]}",

    )
`ip route add #{params[:wireguard_peer][:private_ip]} dev wg0`
      if @wireguard_peer.save
        render json: @wireguard_peer, status: :created   
        ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created wireguard peer for private ip #{@wireguard_peer.private_ip}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
      else
         render json: @wireguard_peer.errors, status: :unprocessable_entity 
      
    end
  end


  def testing
    render json: { message: 'testing' }, status: :ok
    
  end



  # PATCH/PUT /wireguard_peers/1 or /wireguard_peers/1.json
 def update
  @wireguard_peer = WireguardPeer.find_by(id: params[:id])
  old_ip = @wireguard_peer.private_ip

Rails.logger.info ' wireuard peer => #{raw_ips = params[:wireguard_peer][:private_ip]}'
unless @wireguard_peer
  render json: { error: 'Peer not found' }, status: :not_found
  return
end

  # 1. Parse and clean the incoming IP parameter
  raw_ips = params[:wireguard_peer][:private_ip]
  ip_list = raw_ips.split(/[,\s]+/)          # split on commas or whitespace
                 .reject(&:blank?)           # remove empty strings
                 .map(&:strip)                # trim each element

  # 2. Validate we have exactly one IP
  if ip_list.empty?
    render json: { error: 'Private IP cannot be blank' }, status: :unprocessable_entity
    return
  end

  if ip_list.size > 1
    render json: { error: 'Only one private IP allowed when updating a single peer' }, status: :unprocessable_entity
    return
  end

  new_ip = ip_list.first

  # 3. Assign and validate (model validation will check IP format)
  @wireguard_peer.assign_attributes(private_ip: new_ip)

  unless @wireguard_peer.valid?
    render json: @wireguard_peer.errors, status: :unprocessable_entity
    return
  end

  # 4. If IP unchanged, just save and log
  if old_ip == new_ip
    if @wireguard_peer.save
      log_activity('update')
      render json: @wireguard_peer, status: :ok
    else
      render json: @wireguard_peer.errors, status: :unprocessable_entity
    end
    return
  end

  # 5. IP changed – update routes inside a transaction
  ActiveRecord::Base.transaction do
    # Remove old route (ignore if it doesn't exist)
    system('ip', 'route', 'del', old_ip, 'dev', 'wg0')

    # Add new route
    unless system('ip', 'route', 'add', new_ip, 'dev', 'wg0')
      raise "Failed to add route for #{new_ip}"
    end

    # Save the peer
    unless @wireguard_peer.save
      raise @wireguard_peer.errors.full_messages.join(', ')
    end

    log_activity('update')
    render json: @wireguard_peer, status: :ok
  end

rescue => e
  # 6. Clean up if something went wrong
  begin
    system('ip', 'route', 'del', new_ip, 'dev', 'wg0')
  rescue
    # ignore
  end

  begin
    system('ip', 'route', 'add', old_ip, 'dev', 'wg0')
  rescue
    # ignore
  end

  render json: { error: e.message }, status: :unprocessable_entity
end







# ActivtyLog.create(action: 'update', ip: request.remote_ip,
#  description: "Updated wireguard peer for private ip #{@wireguard_peer.private_ip}",
#           user_agent: request.user_agent, user: current_user.username || current_user.email,
#            date: Time.current)


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

def log_activity(action)
  ActivtyLog.create(
    action: action,
    ip: request.remote_ip,
    description: "#{action}d wireguard peer for private ip #{@wireguard_peer.private_ip}",
    user_agent: request.user_agent,
    user: current_user&.username || current_user&.email || 'system',
    date: Time.current
  )
end

    # Use callbacks to share common setup or constraints between actions.
    def set_wireguard_peer
      @wireguard_peer = WireguardPeer.find_by(id:params[:id])
    end

    # Only allow a list of trusted parameters through.
    def wireguard_peer_params
      params.require(:wireguard_peer).permit(:public_key, :allowed_ips, 
      :persistent_keepalive, :private_ip)
    end
end


