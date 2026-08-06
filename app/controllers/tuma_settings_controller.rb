# app/controllers/tuma_settings_controller.rb
class TumaSettingsController < ApplicationController
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
    setting = TumaSetting.find_or_initialize_by(account_id: @account.id)
    render json: serialize(setting)
  end

  def update
    setting = TumaSetting.find_or_initialize_by(account_id: @account.id)

    attrs = tuma_setting_params
    attrs = attrs.except(:api_key) if attrs[:api_key].blank? # don't blank out an existing key

    if setting.update(attrs)
      render json: serialize(setting), status: :ok
    else
      render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def test_connection
    setting = TumaSetting.find_by(account_id: @account.id)
    return render json: { success: false, message: 'No Tuma credentials saved yet' }, status: :unprocessable_entity unless setting

    begin
      TumaService.fetch_token(setting)
      render json: { success: true, message: 'Connected to Tuma successfully' }
    rescue => e
      render json: { success: false, message: e.message }, status: :unprocessable_entity
    end
  end

  private

  def serialize(setting)
    {
      id: setting.id,
      business_email: setting.business_email,
      api_key_present: setting.api_key.present?,
      api_key_masked: setting.api_key.present? ? "#{setting.api_key[0..5]}••••••••" : nil,
      enabled: setting.enabled,
      use_for_hotspot: setting.use_for_hotspot,
      use_for_tv_plans: setting.use_for_tv_plans
    }
  end

  def tuma_setting_params
    params.permit(:business_email, :api_key, :enabled, :use_for_hotspot, :use_for_tv_plans)
  end
end