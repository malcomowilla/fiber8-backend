class NasRoutersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :router_not_found_response
  load_and_authorize_resource

  set_current_tenant_through_filter
  before_action :set_tenant

    before_action :update_last_activity, except: [:router_ping_response]
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
  # def set_my_tenant
  #   set_current_tenant(current_user.account)
  # end


# set_current_tenant_through_filter

# before_action :set_tenant



def router_ping_response

#   request_body1={
#     name: name,
#   validity: validity_period,
#   price: price
#   }


# uri = URI("http://#{router_ip_address}/rest/user-manager/profile/add")
# request = Net::HTTP::Post.new(uri)

# request.basic_auth router_username, router_password
# request.body = request_body1.to_json

# request['Content-Type'] = 'application/json'

#   response = Net::HTTP.start(uri.hostname, uri.port) do |http|
#     http.request(request)
#   end

#   if response.is_a?(Net::HTTPSuccess)
#     data = JSON.parse(response.body)
#     return data['ret']
   

#   else
#     puts "Failed to ping router: #{response.code} - #{response.message}"
#   end
#   
@tenant = ActsAsTenant.current_tenant
router_status = RouterStatus.where(tenant_id: @tenant.id)

    if router_status
      # Render the cached data
      render json: router_status, status: :ok
    else
      # Handle case where cache is empty
      render json: { error: "No router status found for tenant #{@tenant.id}" }, status: :not_found
    end



end




# @tenant = ActsAsTenant.current_tenant
# router_status = RouterStatus.all

#     if router_status
#       # Render the cached data
#       render json: router_status, each_serializer: RouterStatusSerializer, status: :ok

#     else
#       # Handle case where cache is empty
#       render json: { error: "No router status found for tenant #{@tenant.id}" }, status: :not_found
#     end






    def set_tenant
      host = request.headers['X-Subdomain']
      @account = Account.find_by(subdomain: host)
      # @current_account= ActsAsTenant.current_tenant 
         ActsAsTenant.current_tenant = @account
         @current_account= ActsAsTenant.current_tenant
      # EmailConfiguration.configure(@current_account)
      EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])

    Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
    
      # set_current_tenant(@account)
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Invalid tenant' }, status: :not_found
    
    end
    
      def update
        nas_router = find_nas_router
          nas_router.update(nas_router_params)
         ActivtyLog.create(action: 'update', ip: request.remote_ip,
 description: "Updated nas router #{@nas_router.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)

          render json: nas_router      

      end


  # GET /nas_routers or /nas_routers.json
  def index
   
      # Tenant checking is disabled for all code in this block
      @nas_routers = NasRouter.all
      render json: @nas_routers
    end
  

    # def delete
    #   nas_router = find_nas_router

    # nas_router.destroy
    # head :no_content
  
    # end

    def delete
      nas_router = find_nas_router
      
      # Get the WireGuard IP assigned to this router (you'll need to store this when creating)
      # wg_ip = nas_router.ip_address # Assuming you have this field in your model
      
      # Delete the NAS router record first
      nas_router.destroy
      
      # Then remove the WireGuard peer configuration
      # if wg_ip.present?
      #   remove_wireguard_peer(wg_ip)
      # end
      ActivtyLog.create(action: 'delete', ip: request.remote_ip,
 description: "Deleted nas router #{@nas_router.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
      head :no_content
    end

  # POST /nas_routers or /nas_routers.json
  def create
      # Tenant checking is disabled for all code in this block
      @nas_router = NasRouter.create(nas_router_params)

      if @nas_router 
        ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created nas router #{@nas_router.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
        render json: @nas_router, status: :created
        # puts  @nas_router
      else
        render json: {error: 'Error Processing the request' }, status: :unprocessable_entity
      end
    end
  
    
   

  # # PATCH/PUT /nas_routers/1 or /nas_routers/1.json
  # def update
  #   respond_to do |format|
  #     if @nas_router.update(nas_router_params)
  #       format.html { redirect_to nas_router_url(@nas_router), notice: "Nas router was successfully updated." }
  #       format.json { render :show, status: :ok, location: @nas_router }
  #     else
  #       format.html { render :edit, status: :unprocessable_entity }
  #       format.json { render json: @nas_router.errors, status: :unprocessable_entity }
  #     end
  #   end
  

  # DELETE /nas_routers/1 or /nas_routers/1.json

  # def destroy
  #   @nas_router.destroy!

  #   respond_to do |format|
  #     format.html { redirect_to nas_routers_url, notice: "Nas router was successfully destroyed." }
  #     format.json { head :no_content }
  #   end
  # end

  private

  def remove_wireguard_peer(ip)
    wg_config_path = "/etc/wireguard/wg0.conf"
    
    # Read current config
    current_config = File.read(wg_config_path)
    
    # Find the peer block with this IP
    peer_block = current_config.match(/\[Peer\][^\[]+AllowedIPs\s*=\s*#{Regexp.escape(ip)}/m)
    
    if peer_block
      # Remove the peer block from config
      new_config = current_config.gsub(peer_block[0], '')
      
      # Write the modified config back
      File.write(wg_config_path, new_config)
      
      # Remove the peer from running interface
      public_key = peer_block[0].match(/PublicKey\s*=\s*(\S+)/)[1]
      system("wg set wg0 peer #{public_key} remove")
      
      # Restart WireGuard to apply changes
      system("systemctl restart wg-quick@wg0") if Rails.env.production?
    end
  
    # Remove the specific IP from the [Interface] section if no peers remain
    remove_ip_from_interface(wg_config_path, ip)
  end
  
  def remove_ip_from_interface(wg_config_path, ip)
    current_config = File.read(wg_config_path)
    
    # Find the [Interface] section and the line with the specific IP
    new_config = current_config.gsub(/^(\[Interface\][^\[]*)\s*Address\s*=\s*#{Regexp.escape(ip)}[^\n]*/m, '\1')
    
    # Write the modified config back
    File.write(wg_config_path, new_config)
    
    # Restart WireGuard to apply changes
    system("systemctl restart wg-quick@wg0") if Rails.env.production?
  end











  def nas_router_params
    params.require(:nas_router).permit(:name, :ip_address, :username, :password, :location)
  end
    # Use callbacks to share common setup or constraints between actions.
    def find_nas_router
      @nas_router = NasRouter.find(params[:id])
    end


def router_not_found_response
  render json: { error: "Router Not Found" }, status: :not_found
end

    # Only allow a list of trusted parameters through.
   
end
