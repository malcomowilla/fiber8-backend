class AdSettingsController < ApplicationController
  # before_action :set_ad_setting, only: %i[ show edit update destroy ]

  set_current_tenant_through_filter
  before_action :set_tenant
    before_action :update_last_activity
    before_action :set_time_zone


  # GET /ad_settings or /ad_settings.json
  def index
    @ad_settings = AdSetting.all
    render json: @ad_settings
  end




  

def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end


  def update_last_activity
if current_user
      current_user.update!(last_activity_active: Time.current)
    end
    
  end

def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
     ActsAsTenant.current_tenant = @account
    # EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end






def get_ad_settings_by_id
    # @ad_settings = ActsAsTenant.current_tenant.ad_settings
    id = params[:id]
    @ad_settings = AdSetting.find_by(id: id)
    render json: {
       ad_title: @ad_settings.ad_title,
       ad_link: @ad_settings.ad_link,
       position: @ad_settings.position,
       ad_duration: @ad_settings.ad_duration,
       skip_after: @ad_settings.skip_after,
       can_skip: @ad_settings.can_skip,
       ad_enabled: @ad_settings.ad_enabled,
       media_type: @ad_settings.media_type,
       reward_type: @ad_settings.reward_type,
       free_minutes: @ad_settings.free_minutes,
       selected_package: @ad_settings.selected_package
    }
  end



  # POST /ad_settings or /ad_settings.json
  def create
    setting = AdSetting.find_or_initialize_by(ad_title: params[:ad_title],
    )

    setting.assign_attributes(
      ad_title:    params[:ad_title],
      ad_link:     params[:ad_link],
      position:    params[:position],
      ad_duration: params[:ad_duration],
      skip_after:  params[:skip_after],
      can_skip:    params[:can_skip],
      ad_enabled:  params[:ad_enabled],
      media_type:  params[:media_type],
      reward_type: params[:reward_type],
      free_minutes: params[:free_minutes],
      selected_package: params[:selected_package]
    )

    # Attach file if provided
    if params[:media_file].present?
      setting.media_file.purge if setting.media_file.attached?
      setting.media_file.attach(params[:media_file])
    end

    if setting.save
      render json: { success: true, media_url: setting.media_file.attached? ? url_for(setting.media_file) : nil }
    else
      render json: { error: setting.errors.full_messages }, status: 422
    end
  end



  

  # PATCH/PUT /ad_settings/1 or /ad_settings/1.json
  def update
    respond_to do |format|
      if @ad_setting.update(ad_setting_params)
        format.html { redirect_to @ad_setting, notice: "Ad setting was successfully updated." }
        format.json { render :show, status: :ok, location: @ad_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ad_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ad_settings/1 or /ad_settings/1.json
  def destroy
     @ad_setting = AdSetting.find_by(id: params[:id])
    @ad_setting.destroy!

       head :no_content 
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ad_setting
      @ad_setting = AdSetting.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ad_setting_params
      params.require(:ad_setting).permit(:enabled, :to_right, 
      :to_left, :to_top, :account_id)
    end
end
