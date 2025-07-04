class LicenseSettingsController < ApplicationController
  
  set_current_tenant_through_filter

  before_action :set_tenant
  before_action :update_last_activity




 def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end




  def index
    @license_settings = LicenseSetting.all

    render json: @license_settings, each_serializer: LicenseSettingSerializer
  end

  # GET /license_settings/1 or /license_settings/1.json


  # GET /license_settings/new
  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    Rails.logger.info "host #{host}"
    @current_account = host
    # @current_account= ActsAsTenant.current_tenant 
    #  ActsAsTenant.current_tenant = @current_account
    set_current_tenant(@account)
    EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    Rails.logger.info "set_current_tenant #{ActsAsTenant.current_tenant.inspect}"
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end






# Added by WireGuardController for peer vgq9soBxRNQDZTOOxVrv+1QkHJIFnKPRlcygBD37wSQ=
# Add this to your WireGuard server config (/etc/wireguard/wg0.conf)

# PersistentKeepalive = 25 (uncomment if client is behind NAT)

# Added by WireGuardController for peer uHzzEhBQe4VyafN1PtdGSFMQ2eZPc2+VCfK0FctcMDA=

# Added by WireGuardController for peer 6X3/U3Fc5VzD3LN8duihNzPgqrXYHYosk8unAwqF50w=
#

  # POST /license_settings or /license_settings.json
  def create
            host = request.headers['X-Subdomain']


            if  host == 'demo'
              render json: {error: "Demo tenant does not allow license settings creation"}, status: :unprocessable_entity
              
            else
               @license_setting = LicenseSetting.first_or_initialize(

    expiry_warning_days: params[:expiry_warning_days],
     phone_notification: params[:phone_notification],
     phone_number: params[:phone_number]
    )
    @license_setting.update(

    expiry_warning_days: params[:expiry_warning_days],
    phone_notification: params[:phone_notification],
    phone_number: params[:phone_number]
    )

      if @license_setting.save
        ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created license setting #{@license_setting.expiry_warning_days}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
         render json: @license_setting, status: :created
      else
         render json: @license_setting.errors, status: :unprocessable_entity 
      end
            end
   
    end
  

  # PATCH/PUT /license_settings/1 or /license_settings/1.json
  def update
      if @license_setting.update(license_setting_params)
        render json: @license_setting
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @license_setting.errors, status: :unprocessable_entity }
      end
    end
  

  # DELETE /license_settings/1 or /license_settings/1.json
  def destroy
    @license_setting.destroy!

    respond_to do |format|
      format.html { redirect_to license_settings_path, status: :see_other, notice: "License setting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_license_setting
      @license_setting = LicenseSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def license_setting_params
      params.require(:license_setting).permit(:expiry_warning_days, :phone_number, :phone_notification)
    end
end
