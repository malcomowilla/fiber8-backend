
# app/controllers/api/pppoe_plans_controller.rb
class HotspotPlansController < ApplicationController
  # before_action :set_plan, only: [:update]

set_current_tenant_through_filter

before_action :set_tenant, only: [:get_current_hotspot_plan, :allow_get_current_hotspot_plan]
load_and_authorize_resource except: [:allow_get_current_hotspot_plan, :index, :create, :destroy]



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
    default_plan = HotspotPlan.first_or_initialize(
      name: "Hotspot Free Trial",
      hotspot_subscribers: "unlimited",
      price: "0",
      expiry_days: 3,
      status: "active",
        expiry:  Time.current + 3.days

    )
    default_plan.update(
       name: "Hotspot Free Trial",
      hotspot_subscribers: "unlimited",
      price: "0",
      expiry_days: 3,
      status: "active",
              expiry: Time.current + 3.days

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
company_name = params[:plan][:company_name]
expiry_days = params[:plan][:expiry_days]


account = Account.find_by!(subdomain: company_name)

    ActsAsTenant.with_tenant(account) do
    

    @plan = HotspotPlan.first_or_initialize(
      name: params[:plan][:name],
      hotspot_subscribers: params[:plan][:hotspot_subscribers],
      expiry_days: params[:plan][:expiry_days],
      status: "active",
      plan_name: "Hotspot Plan #{params[:plan][:name]}",
      price: params[:plan][:price],
             expiry: Time.current + expiry_days.days

      # billing_cycle: params[:plan][:billing_cycle],
      # condition: false
    )


  #  account_id = Account.find_by(subdomain: params[:plan][:company_name])
  #     @plan.update!(account_id: account_id&.id)

   # @my_admin.password = generate_secure_password(16)
   # @my_admin.password_confirmation = generate_secure_password(16)
   # 
   # @my_admin.password = generate_secure_password(16)
   # @my_admin.password_confirmation = generate_secure_password(16)
    
   # Calculate expiration time

    @plan.update(
      name: params[:plan][:name],
      hotspot_subscribers: params[:plan][:hotspot_subscribers],
      expiry_days: params[:plan][:expiry_days],
      status: "active",
            price: params[:plan][:price],
            plan_name: "Hotspot Plan #{params[:plan][:name]}",
              expiry: Time.current + expiry_days.days


     
    )
    if @plan.save
      render json: @plan, status: :created
    else
      render json: { errors: @plan.errors }, status: :unprocessable_entity
    end
  end
  end





  def update
    @plan = HotspotPlan.find_by(id: params[:id])

    if @plan.update(
      name: params[:plan][:name],
      hotspot_subscribers: params[:plan][:hotspot_subscribers],
      expiry_days: params[:plan][:expiry_days],
      # billing_cycle: params[:plan][:billing_cycle]
    )
      render json: @plan
    else
      render json: { errors: @plan.errors }, status: :unprocessable_entity
    end
  end




  def destroy
    company_name = params[:company_name]
    account = Account.find_by!(subdomain: company_name)

    ActsAsTenant.with_tenant(account) do

      hotspot_plan = HotspotPlan.find_by(id: params[:id])
      if hotspot_plan.nil?
        return render json: { error: "Hotspot plan not found" }, status: :not_found
      end
      hotspot_plan.destroy!
      render json: { message: "Hotspot plan deleted successfully" }, status: :ok
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