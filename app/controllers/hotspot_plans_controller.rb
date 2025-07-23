
# app/controllers/api/pppoe_plans_controller.rb
class HotspotPlansController < ApplicationController
  # before_action :set_plan, only: [:update]

set_current_tenant_through_filter

before_action :set_tenant, only: [:get_current_hotspot_plan, :index, :create]
load_and_authorize_resource except: [:allow_get_current_hotspot_plan, :index, :create]



  # def index
  #   @plans = HotspotPlan.all
  #   render json:@plans
  # end


def index
  plans = HotspotPlan.all

 
  render json: plans
end






  

  def get_current_hotspot_plan
    # @plans = HotspotPlan.all
    # render json: @plans,each_serializer: HotspotPlanSerializer
     plans = HotspotPlan.all

  if plans.empty?
    default_plan = HotspotPlan.create!(
      name: "Free Trial",
      hotspot_subscribers: "unlimited",
      price: "0",
      expiry_days: 3,
      billing_cycle: "trial",
      status: "active",
      condition: false,
      # account_id: ActsAsTenant.current_tenant.id
    )
    plans = [default_plan]
  end

  render json: plans, each_serializer: HotspotPlanSerializer
  end


  def allow_get_current_hotspot_plan
    @plans = HotspotPlan.all
    render json: @plans, each_serializer: HotspotPlanSerializer
  end

  def create
    @plan = HotspotPlan.first_or_initialize(
      name: params[:plan][:name],
      hotspot_subscribers: params[:plan][:hotspot_subscribers],
      expiry_days: params[:plan][:expiry_days],
      billing_cycle: params[:plan][:billing_cycle],
      condition: false
    )


   account_id = Account.find_by(subdomain: params[:plan][:company_name])



   # @my_admin.password = generate_secure_password(16)
   # @my_admin.password_confirmation = generate_secure_password(16)
   # 
   validity_period_units = 'days'
   # @my_admin.password = generate_secure_password(16)
   # @my_admin.password_confirmation = generate_secure_password(16)
   expiry_days = params[:plan][:expiry_days]
    
   # Calculate expiration time
   expiration_time = case validity_period_units.downcase
                     when 'days'
                       Time.current + expiry_days.days
                   
                    
                     else
                       nil
                     end

                     expiry_time_update = expiration_time.strftime("%B %d, %Y at %I:%M %p")
   @plan.update!(account_id: account_id&.id, expiry:  expiry_time_update)

    @plan.update(
      name: params[:plan][:name],
      hotspot_subscribers: params[:plan][:hotspot_subscribers],
      expiry_days: params[:plan][:expiry_days],
      billing_cycle: params[:plan][:billing_cycle],
      condition: false
    )
    if @plan.save
      render json: @plan, status: :created
    else
      render json: { errors: @plan.errors }, status: :unprocessable_entity
    end
  end

  def update
    @plan = HotspotPlan.find_by(id: params[:id])

    if @plan.update(
      name: params[:plan][:name],
      hotspot_subscribers: params[:plan][:hotspot_subscribers],
      expiry_days: params[:plan][:expiry_days],
      billing_cycle: params[:plan][:billing_cycle]
    )
      render json: @plan
    else
      render json: { errors: @plan.errors }, status: :unprocessable_entity
    end
  end

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    # Rails.logger.info "set_current_tenant #{ActsAsTenant.current_tenant.inspect}"
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end

  private

  def set_plan
    @plan = HotspotPlan.find_by(name: params[:name])
  end

  def plan_params
    params.permit(:name, :hotspot_subscribers, :expiry_days, :billing_cycle)
  end
end