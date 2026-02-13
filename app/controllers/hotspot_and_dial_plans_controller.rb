class HotspotAndDialPlansController < ApplicationController

  set_current_tenant_through_filter
  before_action :set_tenant, only: [:get_current_hotspot_and_dial_plan]
  before_action :update_last_activity, only: [:get_current_hotspot_and_dial_plan]
    before_action :set_time_zone, only: [:get_current_hotspot_and_dial_plan]







    def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

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





def update_last_activity
if current_user
      current_user.update_column(:last_activity_active, Time.now.strftime('%Y-%m-%d %I:%M:%S %p'))
    end
    
  end


  
  def index
    @hotspot_and_dial_plans = HotspotAndDialPlan.all
    render json: @hotspot_and_dial_plans
  end

 


        def get_current_hotspot_and_dial_plan
    # @plans = HotspotPlan.all
    # render json: @plans,each_serializer: HotspotPlanSerializer
     plans = HotspotAndDialPlan.all


  if plans.empty?
    default_plan = HotspotAndDialPlan.first_or_initialize(
       name: "Free Trial",
      expiry_days: 14,
      status: "active",
      expiry: Time.current + 14.days,

    )
    default_plan.update(
       name: "Free Trial",
      expiry_days: 14,
      status: "active",
      expiry: Time.current + 14.days,

    )
    plans = [default_plan]
  end

  render json: plans, each_serializer: HotspotAndDialPlanSerializer
  end



  
  def allow_get_current_hotspot_and_dial_plan
    @plans = HotspotAndDialPlan.all
    render json: @plans, each_serializer: HotspotAndDialPlanSerializer
  end





  def create
   company_name = params[:plan][:company_name]
expiry_days = params[:plan][:expiry_days]

account = Account.find_by!(subdomain: company_name)

    ActsAsTenant.with_tenant(account) do
    
    @plan = HotspotAndDialPlan.first_or_initialize(
      name: params[:plan][:name],
      expiry_days: params[:plan][:expiry_days],
      status: "active",
      expiry: Time.current + expiry_days.days,
    )


    @plan.update(
       name: params[:plan][:name],
      expiry_days: params[:plan][:expiry_days],
      status: "active",
      expiry: Time.current + expiry_days.days,
    )

    
  end
end





  def update
    @hotspot_and_dial_plan = set_hotspot_and_dial_plan
      if @hotspot_and_dial_plan.update(hotspot_and_dial_plan_params)
       render json: @hotspot_and_dial_plan, status: :ok
      else
        render json: @hotspot_and_dial_plan.errors, status: :unprocessable_entity 
      end
    
  end

  # DELETE /hotspot_and_dial_plans/1 or /hotspot_and_dial_plans/1.json
  def destroy
   
    company_name = params[:company_name]
    account = Account.find_by!(subdomain: company_name)

    ActsAsTenant.with_tenant(account) do

      hotspot_and_dial_plan = HotspotAndDialPlan.find_by(id: params[:id])
      if hotspot_and_dial_plan.nil?
        return render json: { error: "Hotspot and dial plan not found" }, status: :not_found
      end
       hotspot_and_dial_plan.destroy!
      render json: { message: "Hotspot and dial plan deleted successfully" }, status: :ok
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_and_dial_plan
      @hotspot_and_dial_plan = HotspotAndDialPlan.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def hotspot_and_dial_plan_params
      params.require(:hotspot_and_dial_plan).permit(:expiry, :status, 
      :expiry_days, :company_name, :name)
    end



end
