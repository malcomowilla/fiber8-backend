class AdminSettingsController < ApplicationController
  # before_action :set_admin_setting, only: %i[ show edit update destroy ]


  load_and_authorize_resource except: [:allow_get_admin_settings]
  before_action :update_last_activity
  before_action :set_tenant

  
  # GET /admin_settings or /admin_settings.json
  def index
    # @admin_settings = AdminSetting.all
    # render json: @admin_settings
    @admin_settings = AdminSetting.for_user(current_user.id)
  render json: @admin_settings
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
      current_user.update!(last_activity_active:Time.current)
    end
    
  end



def allow_get_admin_settings
  admin = params[:admin_email]
  @admin = User.find_by(email: admin)
  # @admin_settings = AdminSetting.all
  # render json: @admin_settings
  
  admin_settings = AdminSetting.for_user(@admin.id)
  render json: admin_settings
end








  # POST /admin_settings or /admin_settings.json
  def create
    @admin_setting = AdminSetting.first_or_initialize(
      admin_setting_params.merge(

      user: current_user
      )
      )
    @admin_setting.update!(
      admin_setting_params.merge(

      user: current_user
      )
    )
      if @admin_setting.save
        ActivtyLog.create(action: 'security', ip: request.remote_ip,
 description: "Created admin setting",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
         render json: @admin_setting, status: :created
      else
         render json: @admin_setting.errors, status: :unprocessable_entity 
      end
    
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_setting
      @admin_setting = AdminSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_setting_params
      params.require(:admin_setting).permit(
        :enable_2fa_for_admin_email,:enable_2fa_for_admin_sms,:send_password_via_sms,
        :send_password_via_email, :enable_2fa_for_admin_passkeys, :check_is_inactive,
        :enable_2fa_google_auth,
:checkinactiveminutes, :checkinactivehrs,:checkinactivedays

      )
    end
end
