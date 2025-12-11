class IpNetworksController < ApplicationController




  set_current_tenant_through_filter
  load_and_authorize_resource

  before_action :set_tenant
  before_action :update_last_activity

  before_action :set_time_zone









  def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end


   def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end





  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant  = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end

  # GET /ip_networks or /ip_networks.json
  def index
    @ip_networks = IpNetwork.all
    render json: @ip_networks
  end

  # GET /ip_networks/1 or /ip_networks/1.json
  

  # POST /ip_networks or /ip_networks.json
  def create

    @ip_network = IpNetwork.new(ip_network_params)
ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created ip network #{@ip_network.network}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
      if @ip_network.save
        add_route_to_wireguard(@ip_network.network, @ip_network.subnet_mask)

        render json: @ip_network, status: :created
      else
         render json: @ip_network.errors, status: :unprocessable_entity 
      end
    
  end


  def add_route_to_wireguard(network, mask)
    route = "#{network}/#{mask}"
    command = "ip route add #{route} dev wg0"
  
    Rails.logger.info "Adding route: #{command}"
  
    system(command)
    unless $?.success?
      Rails.logger.error "❌ Failed to add route: #{command}"
      # render json: { error: "Failed to add route: #{command}" }, status: :unprocessable_entity
    end
  end


  # PATCH/PUT /ip_networks/1 or /ip_networks/1.json
  def update
    @ip_network = set_ip_network
      if @ip_network.update(ip_network_params)
        
ActivtyLog.create(action: 'update', ip: request.remote_ip,
 description: "Updated ip network #{@ip_network.network}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
        render json: @ip_network
      else
         render json: @ip_network.errors, status: :unprocessable_entity 
      end
    
  end

  # DELETE /ip_networks/1 or /ip_networks/1.json
  def destroy
    @ip_network = set_ip_network 
    ActivtyLog.create(action: 'delete', ip: request.remote_ip,
 description: "Deleted ip network #{@ip_network.network}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
    @ip_network.destroy!
      head :no_content 
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ip_network
      @ip_network = IpNetwork.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ip_network_params
      params.require(:ip_network).permit(:network, :title, :ip_adress, :subnet_mask, :net_mask,
       :client_host_range, :total_ip_addresses, :nas)
    end

end
