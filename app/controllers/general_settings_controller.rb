class GeneralSettingsController < ApplicationController
    skip_before_action :enforce_ip_allowlist, only: [:create]

  before_action :set_general_setting, only: %i[ show edit update destroy ]

  set_current_tenant_through_filter

  before_action :set_tenant
# before_action :set_time_zone




# def set_time_zone
#   # Rails.logger.info "Setting time zone"
#   Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
#     # Rails.logger.info "Setting time zone #{Time.zone}"

# end


def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
  
  
    set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end


  # GET /general_settings or /general_settings.json
  def index
    @general_settings = GeneralSetting.all
    render json: @general_settings
  end

  
  # POST /general_settings or /general_settings.json
  def create
    
    @general_setting = GeneralSetting.first_or_initialize(general_setting_params)
@general_setting.update(general_setting_params)
ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created general setting #{@general_setting.title}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
      if @general_setting.save
        render json: @general_setting, status: :created
      else
        render json: @general_setting.errors, status: :unprocessable_entity 
      
    end
  end

  # PATCH/PUT /general_settings/1 or /general_settings/1.json
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_general_setting
      @general_setting = GeneralSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    # def general_setting_params
    #   params.require(:general_setting).permit(:title, :timezone,
    #    :allowed_ips, :account_id)
    # end

def general_setting_params
  permitted = params.require(:general_setting).permit(:title, :timezone, :allowed_ips, :account_id)
  if permitted[:allowed_ips].is_a?(String)
    permitted[:allowed_ips] = permitted[:allowed_ips].split(',').map(&:strip).reject(&:empty?)
  end
  permitted
end


end
