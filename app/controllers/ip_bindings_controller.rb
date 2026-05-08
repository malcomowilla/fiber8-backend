class IpBindingsController < ApplicationController
  before_action :set_ip_binding, only: %i[ show edit update destroy ]



  set_current_tenant_through_filter
  before_action :set_tenant

    before_action :update_last_activity
    before_action :set_time_zone






def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end






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




  # GET /ip_bindings or /ip_bindings.json
  def index
    @ip_bindings = IpBinding.all
    render json: @ip_bindings
  end

  # GET /ip_bindings/1 or /ip_bindings/1.json
  def show
  end

  # GET /ip_bindings/new
  def new
    @ip_binding = IpBinding.new
  end

  # GET /ip_bindings/1/edit
  def edit
  end

  # POST /ip_bindings or /ip_bindings.json
  def create
    @ip_binding = IpBinding.new(
router: params[:router],
name: params[:name],
package: params[:package],
mac: params[:mac],
ip: params[:ip],
expiry: params[:expiry],
 device_type: [:device_type],
 router_id: params[:router_id]







    )

      if @ip_binding.save
       render json: @ip_binding 
      else
       render json: @ip_binding.errors, status: :unprocessable_entity 
      end
  end

  # PATCH/PUT /ip_bindings/1 or /ip_bindings/1.json
  def update
                @ip_binding = set_ip_binding
      if @ip_binding.update(
        router: params[:router],
name: params[:name],
package: params[:package],
mac: params[:mac],
ip: params[:ip],
expiry: params[:expiry],
 device_type: [:device_type],
 router_id: params[:router_id]
      )
               render json: @ip_binding 

      else
         render json: @ip_binding.errors, status: :unprocessable_entity 
      end
    
  end

  # DELETE /ip_bindings/1 or /ip_bindings/1.json
  def destroy
     @ip_binding = IpBinding.find(params[:id])
    @ip_binding.destroy!

       head :no_content 
   
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ip_binding
      @ip_binding = IpBinding.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ip_binding_params
      params.require(:ip_binding).permit(:router, :name, :package, :mac, :ip, :expiry,
       :device_type, :account_id, :router_id)
    end
end
