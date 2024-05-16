class NasRoutersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :router_not_found_response

  set_current_tenant_through_filter
  before_action :set_my_tenant

  def set_my_tenant
    set_current_tenant(current_user.account)
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


  # GET /nas_routers/1/edit
  def edit
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
