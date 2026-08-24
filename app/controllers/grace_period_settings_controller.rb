class GracePeriodSettingsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # GET /api/grace_period_setting
  def show
    setting = GracePeriodSetting.find_or_initialize_by(account_id: @account.id) do |s|
      s.grace_period_value = 1
      s.grace_period_unit = 'days'
      s.enabled = true
    end
    setting.save if setting.new_record?
    render json: setting
  end

  # PATCH /api/grace_period_setting
  def update
    setting = GracePeriodSetting.find_or_initialize_by(account_id: @account.id)
    if setting.update(grace_period_params)
      render json: setting
    else
      render json: { error: setting.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def grace_period_params
    params.require(:grace_period_setting).permit(:grace_period_value, :grace_period_unit, :enabled)
  end
end