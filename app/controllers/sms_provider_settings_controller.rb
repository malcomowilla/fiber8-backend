class SmsProviderSettingsController < ApplicationController




  set_current_tenant_through_filter


  
  before_action :set_tenant


  # GET /sms_provider_settings or /sms_provider_settings.json
  def index
    @sms_provider_settings = SmsProviderSetting.all
    render json: @sms_provider_settings
  end



  def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
  
  
    set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
   end
  # GET /sms_provider_settings/1 or /sms_provider_settings/1.json


  # GET /sms_provider_settings/1/edit
 

  # POST /sms_provider_settings or /sms_provider_settings.json
  def create
    @sms_provider_setting = SmsProviderSetting.first_or_initialize(sms_provider_setting_params)
    @sms_provider_setting.update(sms_provider_setting_params)

      if @sms_provider_setting.save
        render json: @sms_provider_setting, status: :created
      else
        render json: @sms_provider_setting.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /sms_provider_settings/1 or /sms_provider_settings/1.json
  def update
    respond_to do |format|
      if @sms_provider_setting.update(sms_provider_setting_params)
        format.html { redirect_to @sms_provider_setting, notice: "Sms provider setting was successfully updated." }
        format.json { render :show, status: :ok, location: @sms_provider_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sms_provider_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sms_provider_settings/1 or /sms_provider_settings/1.json
  def destroy
    @sms_provider_setting.destroy!

    respond_to do |format|
      format.html { redirect_to sms_provider_settings_path, status: :see_other, notice: "Sms provider setting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sms_provider_setting
      @sms_provider_setting = SmsProviderSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def sms_provider_setting_params
      params.require(:sms_provider_setting).permit(:sms_provider)
    end
end
