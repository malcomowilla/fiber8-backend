class TvPlansController < ApplicationController
  load_and_authorize_resource except: [:allow_get_tv_plans]
  set_current_tenant_through_filter
  before_action :set_tenant

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # ADMIN: List all TV plans (with router info)
  def index
    tv_plans = TvPlan.includes(:nas_router).order(:position, :id)
    render json: tv_plans.map { |plan| plan_with_router(plan) }
  end

  # PUBLIC: TV plans for the hotspot page, filtered per router.
  # The page sends ?router=<router name>. Plans assigned to another router
  # are hidden; plans with no router assigned still show everywhere.
  def allow_get_tv_plans
    account_id = ActsAsTenant.current_tenant&.id
    scope = TvPlan.where(active: true, account_id: account_id)

    router_name = (params[:router].presence || params[:nas_router]).to_s.strip

    if router_name.present?
      router = NasRouter.where(account_id: account_id)
                        .where('LOWER(TRIM(name)) = ?', router_name.downcase)
                        .first

      scope = if router
                scope.where(nas_router_id: [router.id, nil])
              else
                scope.where(nas_router_id: nil)
              end
    end

    Rails.logger.info "allow_get_tv_plans router=#{router_name.inspect} count=#{scope.count}"

    render json: scope.includes(:nas_router).order(:position, :id).map { |plan| plan_with_router(plan) }
  end

  # CREATE
  def create
    @tv_plan = TvPlan.new(tv_plan_params)

    if tv_plan_params[:nas_router_id].present?
      router = NasRouter.find_by(id: tv_plan_params[:nas_router_id])
      return render json: { error: 'Router not found' }, status: :not_found unless router
    end

    if @tv_plan.save
      render json: plan_with_router(@tv_plan), status: :created
    else
      render json: @tv_plan.errors, status: :unprocessable_entity
    end
  end

  # UPDATE
  def update
    @tv_plan = TvPlan.find_by(id: params[:id])
    return render json: { error: 'Not found' }, status: :not_found unless @tv_plan

    if tv_plan_params[:nas_router_id].present? && tv_plan_params[:nas_router_id].to_s != @tv_plan.nas_router_id.to_s
      router = NasRouter.find_by(id: tv_plan_params[:nas_router_id])
      return render json: { error: 'Router not found' }, status: :not_found unless router
    end

    if @tv_plan.update(tv_plan_params)
      render json: plan_with_router(@tv_plan)
    else
      render json: @tv_plan.errors, status: :unprocessable_entity
    end
  end

  # DELETE
  def destroy
    @tv_plan = TvPlan.find_by(id: params[:id])
    return render json: { error: 'Not found' }, status: :not_found unless @tv_plan

    @tv_plan.destroy!
    render json: { message: 'TV plan deleted' }
  end

  private

  def tv_plan_params
    params.permit(
      :name,
      :price,
      :validity,
      :validity_period_units,
      :download_limit,
      :upload_limit,
      :active,
      :position,
      :nas_router_id
    )
  end

  def plan_with_router(plan)
    {
      id: plan.id,
      name: plan.name,
      price: plan.price,
      validity: plan.validity,
      validity_period_units: plan.validity_period_units,
      download_limit: plan.download_limit,
      upload_limit: plan.upload_limit,
      active: plan.active,
      position: plan.position,
      nas_router_id: plan.nas_router_id,
      router_name: plan.nas_router&.name,
      router_ip: plan.nas_router&.ip_address,
      created_at: plan.created_at,
      updated_at: plan.updated_at
    }
  end
end