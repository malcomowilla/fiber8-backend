class NasRoutersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :router_not_found_response
  load_and_authorize_resource

  set_current_tenant_through_filter
  before_action :set_tenant

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
router_status = RouterStatus.where(tenant_id: @tenant.id).order(checked_at: :desc).first

    if router_status
      # Render the cached data
      render json: router_status, each_serializer: RouterStatusSerializer , status: :ok
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
         

          render json: nas_router      

      end


  # GET /nas_routers or /nas_routers.json
  def index
   
      # Tenant checking is disabled for all code in this block
      @nas_routers = NasRouter.all
      render json: @nas_routers
    end
  

    def delete
      nas_router = find_nas_router

    nas_router.destroy
    head :no_content
  
    end



  # POST /nas_routers or /nas_routers.json
  def create
      # Tenant checking is disabled for all code in this block
      @nas_router = NasRouter.create(nas_router_params)

      if @nas_router 
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
  def nas_router_params
    params.require(:nas_router).permit(:name, :ip_address, :username, :password)
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
