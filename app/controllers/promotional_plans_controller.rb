# app/controllers/promotional_plans_controller.rb
class PromotionalPlansController < ApplicationController
  load_and_authorize_resource except: [:allow_get_active_promotions]

  set_current_tenant_through_filter

  before_action :set_tenant
  before_action :update_last_activity, except: [:allow_get_active_promotions]
  before_action :set_time_zone, except: [:allow_get_active_promotions]
  before_action :set_promotional_plan, only: [:show, :update, :destroy]

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def update_last_activity
    current_user&.update_column(:last_activity_active, Time.now.strftime('%Y-%m-%d %I:%M:%S %p'))
  end

  def set_time_zone
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
  end

  # GET /promotional_plans
  def index
    @promotional_plans = PromotionalPlan.includes(:hotspot_package).ordered_for_display
    render json: @promotional_plans.as_json(
      include: { hotspot_package: { only: [:id, :name, :price, :valid, :download_limit, :upload_limit] } },
      methods: [:promotional_price, :original_price, :discount_amount, :savings_percent, :sold_out?, :remaining_stock, :currently_active?]
    )
  end

  # GET /promotional_plans/:id
  def show
    render json: @promotional_plan.as_json(
      methods: [:promotional_price, :original_price, :discount_amount, :savings_percent]
    )
  end

  # GET /api/hotspot_active_promotions (public, no auth) — used by the captive portal
  def allow_get_active_promotions
    promos = PromotionalPlan
             .active_flagged
             .within_date_range
             .includes(:hotspot_package)
             .ordered_for_display
             .select(&:currently_active?)

    render json: promos.map(&:as_public_json)
  end

  # POST /promotional_plans
  def create
    @promotional_plan = PromotionalPlan.new(promotional_plan_params)
    @promotional_plan.account_id = @account.id

    if @promotional_plan.save
      ActivtyLog.create(action: 'create', ip: request.remote_ip,
                         description: "Created promotional plan #{@promotional_plan.name}",
                         user_agent: request.user_agent, user: current_user.username || current_user.email,
                         date: Time.current)
      render json: @promotional_plan, status: :created
    else
      render json: @promotional_plan.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /promotional_plans/:id
  def update
    if @promotional_plan.update(promotional_plan_params)
      ActivtyLog.create(action: 'update', ip: request.remote_ip,
                         description: "Updated promotional plan #{@promotional_plan.name}",
                         user_agent: request.user_agent, user: current_user.username || current_user.email,
                         date: Time.current)
      render json: @promotional_plan
    else
      render json: @promotional_plan.errors, status: :unprocessable_entity
    end
  end

  # DELETE /promotional_plans/:id
  def destroy
    ActivtyLog.create(action: 'delete', ip: request.remote_ip,
                       description: "Deleted promotional plan #{@promotional_plan.name}",
                       user_agent: request.user_agent, user: current_user.username || current_user.email,
                       date: Time.current)
    @promotional_plan.destroy
    render json: { message: 'Promotional plan deleted successfully' }, status: :ok
  end

  private

  def set_promotional_plan
    @promotional_plan = PromotionalPlan.find_by(id: params[:id])
    render(json: { error: 'Promotional plan not found' }, status: :not_found) unless @promotional_plan
  end

  def promotional_plan_params
    params.permit(
      :hotspot_package_id,
      :name,
      :badge_text,
      :description,
      :start_date,
      :end_date,
      :recurrence_type,
      :daily_start_time,
      :daily_end_time,
      :discount_type,
      :discount_value,
      :max_redemptions,
      :display_priority,
      :show_countdown_timer,
      :show_stock_indicator,
      :active
    )
  end
end