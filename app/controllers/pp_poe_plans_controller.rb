# app/controllers/api/pppoe_plans_controller.rb
class PpPoePlansController  < ApplicationController
  # before_action :set_plan, only: [:update]

set_current_tenant_through_filter 

before_action :set_tenant, only: [:get_current_plan, :allow_get_current_plan]
load_and_authorize_resource except: [:allow_get_current_plan, :index, :create, :destroy]

  def index
    @plans = PpPoePlan.all
    render json: @plans,each_serializer: PpPoePlanSerializer
  end


  def get_current_plan
    # @plans = PpPoePlan.all
    # render json: @plans,each_serializer: PpPoePlanSerializer
      plans = PpPoePlan.all

  if plans.empty?
    default_plan = PpPoePlan.first_or_initialize(
      name: "PPPOE Free Trial",
      maximum_pppoe_subscribers: "unlimited",
      
      price: "0",
      expiry_days: 14,
      status: "active",
       expiry: Time.current + 14.days

    )
    default_plan.update(
       name: "PPPOE Free Trial",
      maximum_pppoe_subscribers: "unlimited",
      price: "0",
      expiry_days: 14,
      status: "active",
       expiry: Time.current + 14.days

    )
    plans = [default_plan]
  end

  render json: plans, each_serializer: PpPoePlanSerializer
  end





  def allow_get_current_plan
    @plans = PpPoePlan.all
    render json: @plans,each_serializer: PpPoePlanSerializer
  end




  def destroy
    company_name = params[:company_name]
    account = Account.find_by!(subdomain: company_name)

    ActsAsTenant.with_tenant(account) do

      pppoe_plan = PpPoePlan.find_by(id: params[:id])
      if pppoe_plan.nil?
        return render json: { error: "PPPOE plan not found" }, status: :not_found
      
      end
      pppoe_plan.destroy!
      render json: { message: "PPPOE plan deleted successfully" }, status: :ok
    end
  end



  def create
expiry_days = params[:plan][:expiry_days]
company_name = params[:plan][:company_name]
account = Account.find_by!(subdomain: company_name)

ActsAsTenant.with_tenant(account) do
    @plan = PpPoePlan.first_or_initialize(
      name: params[:plan][:name],
      maximum_pppoe_subscribers: params[:plan][:maximum_pppoe_subscribers],
      expiry_days: params[:plan][:expiry_days],
      status: "active",
      plan_name:"PPPoE Plan #{params[:plan][:name]}",
      price: params[:plan][:price],
      expiry: Time.current 
      #  expiry:   Time.current + expiry_days.days
      # billing_cycle: params[:plan][:billing_cycle],
      # condition: false
    )


  #  account_id = Account.find_by(subdomain: params[:plan][:company_name])

# Rails.logger.info "account_id: #{account_id.inspect}"
   # @my_admin.password = generate_secure_password(16)
   # @my_admin.password_confirmation = generate_secure_password(16)
    
   # Calculate expiration time
  
          #  @plan.update!(account_id: account_id.id)


                     
    @plan.update(
      name: params[:plan][:name],
      maximum_pppoe_subscribers: params[:plan][:maximum_pppoe_subscribers],
      expiry_days: params[:plan][:expiry_days],
       status: "active",
      price: params[:plan][:price],
            #  expiry:   Time.current + expiry_days.days,
                   plan_name:"PPPoE Plan #{params[:plan][:name]}",
                         expiry: Time.current 



      # billing_cycle: params[:plan][:billing_cycle],
      # condition: false
    )
    if @plan.save
      render json: @plan, status: :created
    else
      render json: { errors: @plan.errors }, status: :unprocessable_entity
    end
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

  def update
    @plan = PpPoePlan.new(plan_params)

    if @plan.update(plan_params)
      render json: @plan
    else
      render json: { errors: @plan.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_plan
    @plan = PpPoePlan.find_by(name: params[:name])
  end

  def plan_params
    params.permit(:name, :maximum_pppoe_subscribers, 
    :expiry_days, :billing_cycle)
  end
end



