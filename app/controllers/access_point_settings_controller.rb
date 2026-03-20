class AccessPointSettingsController < ApplicationController



  set_current_tenant_through_filter
  before_action :set_tenant


  # GET /access_point_settings or /access_point_settings.json
  def index
    @access_point_settings = AccessPointSetting.all
    render json: @access_point_settings
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



  



  # POST /access_point_settings or /access_point_settings.json
  def create
    @access_point_setting = AccessPointSetting.first_or_initialize(access_point_setting_params)
     @access_point_setting.update(access_point_setting_params)

      if @access_point_setting.save
        render json: @access_point_setting, status: :created
      else
       render json: @access_point_setting.errors, status: :unprocessable_entity 

      end
  end





  
  # PATCH/PUT /access_point_settings/1 or /access_point_settings/1.json
  def update
    respond_to do |format|
      if @access_point_setting.update(access_point_setting_params)
        format.html { redirect_to @access_point_setting, notice: "Access point setting was successfully updated." }
        format.json { render :show, status: :ok, location: @access_point_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @access_point_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /access_point_settings/1 or /access_point_settings/1.json
  def destroy
    @access_point_setting.destroy!

    respond_to do |format|
      format.html { redirect_to access_point_settings_path, status: :see_other, notice: "Access point setting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_access_point_setting
      @access_point_setting = AccessPointSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def access_point_setting_params
      params.require(:access_point_setting).permit(:notification_when_unreachable,
       :unreachable_duration_minutes, :notification_phone_number,
        :account_id)
    end
end
