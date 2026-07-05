class AdSettingsController < ApplicationController
  # before_action :set_ad_setting, only: %i[ show edit update destroy ]
require 'cloudinary'

  set_current_tenant_through_filter
  before_action :set_tenant
    before_action :update_last_activity
    before_action :set_time_zone


  # GET /ad_settings or /ad_settings.json
  def index
    @ad_settings = AdSetting.all
    render json: @ad_settings
  end


  def allow_get_ads
    @account = ActsAsTenant.current_tenant
    # @ad_settings = @account.ad_settings
 @ad_settings = AdSetting.where(account_id: @account.id)
   render json: @ad_settings.map do |ad|
  {
    ad_title: ad.ad_title,
    # media_url is where the actual Cloudinary URL lives (see create/update).
    # media_file (ActiveStorage) is never attached anywhere in this controller,
    # so media_file.attached? was always false and ad_link was always nil.
    ad_link: ad&.ad_link,
    media_url: ad&.media_url,

    position: ad&.position,
    ad_duration: ad&.ad_duration,
    skip_after: ad&.skip_after,
    can_skip: ad&.can_skip,
    ad_enabled: ad&.ad_enabled,
    media_type: ad&.media_type,
    reward_type: ad&.reward_type,
    free_minutes: ad&.free_minutes,
    selected_package: ad&.selected_package,
     design_config:     ad.design_config,      
      design_background: ad.design_background,  
      link_type:         ad.link_type,          
  
  }
end
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
    # tunnel_host = fetch_loophole_tunnel_hostname
    id = params[:id]
    @ad_settings = AdSetting.find_by_id(id)
    render json: {
       ad_title: @ad_settings.ad_title,
      #  ad_link: @ad_settings&.media_file&.attached? ? rails_blob_url(@ad_settings&.media_file,
      #  host: tunnel_host, protocol: 'https', port: nil,
      # ) : nil,
      # ad_link is the tap-through link. media_url is the actual uploaded
      # image/video (Cloudinary URL). These are two different fields and both
      # need to be sent back, or the frontend has nothing to preview/render.
      ad_link: @ad_settings&.ad_link,
      media_url: @ad_settings&.media_url,
       position: @ad_settings.position,
       ad_duration: @ad_settings.ad_duration,
       skip_after: @ad_settings.skip_after,
       can_skip: @ad_settings.can_skip,
       ad_enabled: @ad_settings.ad_enabled,
       media_type: @ad_settings.media_type,
       reward_type: @ad_settings.reward_type,
       free_minutes: @ad_settings.free_minutes,
       selected_package: @ad_settings.selected_package,
        design_config:     @ad_settings.design_config,      
      design_background: @ad_settings.design_background,  
       design_canvas_w: @ad_settings.design_canvas_w,
      design_canvas_h: @ad_settings.design_canvas_h,
      link_type:         @ad_settings.link_type,  
    }
  end



  # POST /ad_settings or /ad_settings.json
  def create
     host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    setting = AdSetting.find_or_initialize_by(
      
    ad_title: params[:ad_title],
    )

      cloudinary_url = nil

  if params[:media_file].present?
    uploaded = Cloudinary::Uploader.upload(
      params[:media_file].tempfile.path
    )
    cloudinary_url = uploaded["secure_url"]
  elsif params[:media_url].present?
    cloudinary_url = params[:media_url]
  end



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
      selected_package: params[:selected_package],
      media_url: cloudinary_url,
      design_config: params[:design_config],   
      design_canvas_w: params[:design_canvas_w],  
      design_canvas_h: params[:design_canvas_h],
      design_background: params[:design_background],  
      link_type:         params[:link_type],    

    )

    # # Attach file if provided
    # if params[:media_file].present?
    #   setting.media_file.purge if setting.media_file.attached?
    #   setting.media_file.attach(params[:media_file])
    # end
 if setting.save
    render json: { success: true, media_url: cloudinary_url }
    else
      render json: { error: setting.errors.full_messages }, status: 422
    end
  end



  

  # PATCH/PUT /ad_settings/1 or /ad_settings/1.json
 def update
  @ad_setting = AdSetting.find_by_id(params[:id])

  cloudinary_url = @ad_setting.media_url
  if params[:media_file].present?
    uploaded = Cloudinary::Uploader.upload(params[:media_file].tempfile.path)
    cloudinary_url = uploaded["secure_url"]
  elsif params[:media_url].present?
    cloudinary_url = params[:media_url]
  end

  if @ad_setting.update(
    ad_title:    params[:ad_title],
    ad_link:     params[:ad_link],
    position:    params[:position],
    ad_duration: params[:ad_duration],
    skip_after:  params[:skip_after],
    can_skip:    params[:can_skip],
    ad_enabled:  params[:ad_enabled],
    media_type:  params[:media_type],
    ad_format:   params[:ad_format],
    reward_type: params[:reward_type],
    free_minutes: params[:free_minutes],
    selected_package: params[:selected_package],
    media_url: cloudinary_url,
    design_config: params[:design_config],
    design_canvas_w: params[:design_canvas_w],
    design_canvas_h: params[:design_canvas_h],
    design_background: params[:design_background],
    link_type: params[:link_type],
  )
    render json: @ad_setting
  else
    render json: @ad_setting.errors, status: :unprocessable_entity
  end
end

  # DELETE /ad_settings/1 or /ad_settings/1.json
  def destroy
     @ad_setting = AdSetting.find_by_id(params[:id])
    @ad_setting.destroy!

       head :no_content 
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ad_setting
      @ad_setting = AdSetting.find_by_id(params[:id])
    end


# def fetch_loophole_tunnel_hostname
#   log_output = `journalctl -u loophole -n 200 --no-pager`.strip
#     # output = File.read("/var/log/loophole.log")

#   match = log_output.match(%r{https://([a-z0-9\-]+\.loophole\.site)})
#   match ? match[1] : nil
# end

    # Only allow a list of trusted parameters through.
    def ad_setting_params
      params.require(:ad_setting).permit(:enabled, :to_right, 
      :to_left, :to_top, :account_id)
    end
end