class WireguardPeersController < ApplicationController


before_action :update_last_activity
before_action :set_tenant



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
      private_ip:  "#{params[:wireguard_peer][:private_ip]}/#{params[:wireguard_peer][:subnet_mask]}",

    )
`ip route add #{params[:wireguard_peer][:private_ip]}/#{params[:wireguard_peer][:subnet_mask]} dev wg0`
      if @wireguard_peer.save
        render json: @wireguard_peer, status: :created   
      else
         render json: @wireguard_peer.errors, status: :unprocessable_entity 
      
    end
  end

  # PATCH/PUT /wireguard_peers/1 or /wireguard_peers/1.json
  def update
          @wireguard_peer = WireguardPeer.find(params[:id])

      if @wireguard_peer.update(
      private_ip:  "#{params[:wireguard_peer][:private_ip]}/#{params[:wireguard_peer][:subnet_mask]}",


      )
        render json: @wireguard_peer, status: :ok
      else
         render json: @wireguard_peer.errors, status: :unprocessable_entity 
      end
    
  end

  # DELETE /wireguard_peers/1 or /wireguard_peers/1.json
  def destroy
          @wireguard_peer = WireguardPeer.find(params[:id])

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


