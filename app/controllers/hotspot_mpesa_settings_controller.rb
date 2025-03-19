class HotspotMpesaSettingsController < ApplicationController

  set_current_tenant_through_filter


  
  before_action :set_tenant
  # GET /hotspot_mpesa_settings or /hotspot_mpesa_settings.json
 



  def index
    @hotspot_mpesa_settings =  HotspotMpesaSetting.find_by(account_type: params[:account_type])
    render json: @hotspot_mpesa_settings
  end





  def saved_hotspot_mpesa_settings
    
    @hotspot_mpesa_settings = HotspotMpesaSetting.all
    render json: @hotspot_mpesa_settings
  end


  def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
  
  
    set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
   end
  # GET /hotspot_mpesa_settings/1 or /hotspot_mpesa_settings/1.json
 

  # GET /hotspot_mpesa_settings/new
 
  # POST /hotspot_mpesa_settings or /hotspot_mpesa_settings.json
  def create
    # @sms_setting = SmsSetting.find_or_initialize_by(sms_setting_params)
      @hotspot_mpesa_setting_setting = HotspotMpesaSetting.find_or_initialize_by(
        consumer_key: params[:consumer_key],
        consumer_secret: params[:consumer_secret],
      ) 
      @hotspot_mpesa_setting_setting.update(
      passkey: params[:passkey],
      consumer_key: params[:consumer_key],
        consumer_secret: params[:consumer_secret],
      short_code: params[:short_code],
        account_type: params[:account_type]

    )
      if @hotspot_mpesa_setting_setting.save 
        render json: @hotspot_mpesa_setting_setting, status: :created
      else
        render json: @hotspot_mpesa_setting_setting.errors, status: :unprocessable_entity 
      
    end
  end

  # PATCH/PUT /hotspot_mpesa_settings/1 or /hotspot_mpesa_settings/1.json
  def update
    respond_to do |format|
      if @hotspot_mpesa_setting.update(hotspot_mpesa_setting_params)
        format.html { redirect_to @hotspot_mpesa_setting, notice: "Hotspot mpesa setting was successfully updated." }
        format.json { render :show, status: :ok, location: @hotspot_mpesa_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @hotspot_mpesa_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hotspot_mpesa_settings/1 or /hotspot_mpesa_settings/1.json
  def destroy
    @hotspot_mpesa_setting.destroy!

    respond_to do |format|
      format.html { redirect_to hotspot_mpesa_settings_path, status: :see_other, notice: "Hotspot mpesa setting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_mpesa_setting
      @hotspot_mpesa_setting = HotspotMpesaSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def hotspot_mpesa_setting_params
      params.require(:hotspot_mpesa_setting).permit(:account_type, :short_code, :consumer_key, 
      :consumer_secret, :passkey)
    end
end
