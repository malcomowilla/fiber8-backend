# app/controllers/hotspot_loyalty_settings_controller.rb
class HotspotLoyaltySettingsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def show
    setting = HotspotLoyaltySetting.find_or_initialize_by(account_id: @account.id)
    render json: serialize(setting)
  end

  def update
    setting = HotspotLoyaltySetting.find_or_initialize_by(account_id: @account.id)
    setting.assign_attributes(loyalty_params)
    if setting.save
      render json: serialize(setting)
    else
      render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def loyalty_params
    params.permit(:enabled, :earn_rate_percent, :max_points,
      :expire_after_days, :expire_warning_days, :expire_min_balance)
  end

  def serialize(setting)
    {
      enabled: setting.enabled,
      earn_rate_percent: setting.earn_rate_percent,
      max_points: setting.max_points,
      expire_after_days: setting.expire_after_days,
      expire_warning_days: setting.expire_warning_days,
      expire_min_balance: setting.expire_min_balance
    }
  end
end