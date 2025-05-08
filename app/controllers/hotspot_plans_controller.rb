
# app/controllers/api/pppoe_plans_controller.rb
class HotspotPlansController < ApplicationController
  # before_action :set_plan, only: [:update]

set_current_tenant_through_filter

before_action :set_tenant


  def index
    @plans = HotspotPlan.all
    render json:  @plans, each_serializer: HotspotPlanSerializer
  end

  def create
    @plan = HotspotPlan.create(
      name: params[:plan][:name],
      hotspot_subscribers: params[:plan][:hotspot_subscribers],
      expiry_days: params[:plan][:expiry_days],
      billing_cycle: params[:plan][:billing_cycle]
    )
    if @plan.save
      render json: @plan, status: :created
    else
      render json: { errors: @plan.errors }, status: :unprocessable_entity
    end
  end

  def update
    @plan = HotspotPlan.new(plan_params)
    if @plan.update(plan_params)
      render json: @plan
    else
      render json: { errors: @plan.errors }, status: :unprocessable_entity
    end
  end

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    @current_account= ActsAsTenant.current_tenant 
    EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    Rails.logger.info "set_current_tenant #{ActsAsTenant.current_tenant.inspect}"
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