class IpNetworksController < ApplicationController




  set_current_tenant_through_filter

  before_action :set_tenant





  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    @current_account =ActsAsTenant.current_tenant 
    EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])
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

      if @ip_network.save
        render json: @ip_network, status: :created
      else
         render json: @ip_network.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /ip_networks/1 or /ip_networks/1.json
  def update
    @ip_network = set_ip_network
      if @ip_network.update(ip_network_params)
        render json: @ip_network
      else
         render json: @ip_network.errors, status: :unprocessable_entity 
      end
    
  end

  # DELETE /ip_networks/1 or /ip_networks/1.json
  def destroy
    @ip_network = set_ip_network 
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
