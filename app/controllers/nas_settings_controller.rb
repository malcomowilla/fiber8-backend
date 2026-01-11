class NasSettingsController < ApplicationController
  # before_action :set_nas_setting, only: %i[ show edit update destroy ]
   set_current_tenant_through_filter

  before_action :set_tenant

  before_action :update_last_activity
before_action :set_time_zone

  # GET /nas_settings or /nas_settings.json
  def index
    @nas_settings = NasSetting.all
    render json: @nas_settings
  end


  def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

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


  def update_last_activity
if current_user
      current_user.update!(last_activity_active: Time.current)
    end
    
  end



  # GET /nas_settings/new
  

  # POST /nas_settings or /nas_settings.json
  def create
    @nas_setting = NasSetting.first_or_initialize(nas_setting_params)
    @nas_setting.update(nas_setting_params)
      if @nas_setting.save
         render json: @nas_setting, status: :created
      else
       render json: @nas_setting.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /nas_settings/1 or /nas_settings/1.json
  
  # DELETE /nas_settings/1 or /nas_settings/1.json
  def destroy
    @nas_setting.destroy!

    respond_to do |format|
      format.html { redirect_to nas_settings_path, status: :see_other, notice: "Nas setting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_nas_setting
      @nas_setting = NasSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def nas_setting_params
      params.require(:nas_setting).permit(:notification_when_unreachable, 
      :unreachable_duration_minutes, :notification_phone_number)
    end
end
