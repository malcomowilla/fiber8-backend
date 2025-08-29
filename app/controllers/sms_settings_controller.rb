class SmsSettingsController < ApplicationController
  # before_action :set_sms_setting, only: %i[ show edit update destroy ]
  load_and_authorize_resource
  before_action :update_last_activity

  # GET /sms_settings or /sms_settings.json
  # 

  set_current_tenant_through_filter
  before_action :set_tenant
  def index
    Rails.logger.info "current tenant sms settin: #{ActsAsTenant.current_tenant.sms_setting.sms_provider}"
    @sms_settings = SmsSetting.find_by(sms_provider: params[:provider])

    render json: @sms_settings
  end





   def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end



  def saved_sms_settings
    
    # @sms_settings = SmsSetting.all
    # render json: @sms_settings
    # @sms_settings = SmsSetting.order(updated_at: :asc)
    @sms_settings = SmsSetting.order(sms_setting_updated_at: :desc)
  render json: @sms_settings
  end




  def set_tenant
  host = request.headers['X-Subdomain']
  @account = Account.find_by(subdomain: host)
  ActsAsTenant.current_tenant = @account
  EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])

  # set_current_tenant(@account)
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Invalid tenant' }, status: :not_found

  end





  
  def create
    # @sms_setting = SmsSetting.find_or_initialize_by(sms_setting_params)
      @sms_setting = SmsSetting.find_or_initialize_by(
        api_secret: params[:api_secret],
        api_key: params[:api_key],
      ) 
    @sms_setting.update!(
      api_key: params[:api_key],
      api_secret: params[:api_secret],
      sender_id: params[:sender_id],
      short_code: params[:short_code],
      sms_provider: params[:sms_provider],
      partnerID: params[:partnerID],
      sms_setting_updated_at: Time.current

    )
      if  @sms_setting.save 
        ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created SMS settings #{@sms_setting.short_code}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
        render json: @sms_setting, status: :created
      else
        render json: @sms_setting.errors, status: :unprocessable_entity 
      
    end
  end

  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sms_setting
      @sms_setting = SmsSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def sms_setting_params
      params.require(:sms_setting).permit(:api_key, :api_secret, :sender_id, :short_code, :username, 
      :sms_provider, :partnerID
      )
    end
end
