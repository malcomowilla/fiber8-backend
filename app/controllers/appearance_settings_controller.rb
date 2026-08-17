class AppearanceSettingsController < ApplicationController



    set_current_tenant_through_filter

  before_action :set_tenant
      before_action :set_time_zone

    before_action :update_last_activity






     def update_last_activity
if current_user
      current_user.update!(last_activity_active: Time.current)
    end  
  end





    def set_time_zone
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone

end


  def show
    setting = AppearanceSetting.find_by(account: @tenant_account)
    render json: setting ? serialize(setting) : {}
  end

  def create
    setting = AppearanceSetting.find_or_initialize_by(account: @tenant_account)
    setting.assign_attributes(appearance_setting_params)
    if setting.save
      render json: serialize(setting)
    else
      render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_tenant
    subdomain = request.headers['X-Subdomain'] || request.subdomain
    @tenant_account = Account.find_by!(subdomain: subdomain)
    ActsAsTenant.current_tenant = @tenant_account
  end

  def appearance_setting_params
    params.require(:appearance_setting).permit(
      :color_hsl, :color_preset_id, :font_key, :display_font_key,
      :font_italic, :display_font_italic, :radius, :density, :mode
    )
  end

  def serialize(setting)
    {
      color_hsl: setting.color_hsl,
      color_preset_id: setting.color_preset_id,
      font_key: setting.font_key,
      display_font_key: setting.display_font_key,
      font_italic: setting.font_italic,
      display_font_italic: setting.display_font_italic,
      radius: setting.radius,
      density: setting.density,
      mode: setting.mode,
    }
  end
end