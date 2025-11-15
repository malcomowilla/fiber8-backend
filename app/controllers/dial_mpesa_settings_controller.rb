class DialMpesaSettingsController < ApplicationController




  load_and_authorize_resource

  set_current_tenant_through_filter


  
  before_action :set_tenant
  # GET /hotspot_mpesa_settings or /hotspot_mpesa_settings.json
  before_action :update_last_activity
 


    def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
  
  
    set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
   end



   def update_last_activity
if current_user
      current_user.update_column(:last_activity_active, Time.now.strftime('%Y-%m-%d %I:%M:%S %p'))
    end
    
  end





  


  # GET /dial_mpesa_settings or /dial_mpesa_settings.json
  def index
    @dial_mpesa_settings = DialMpesaSetting.all
    render json: @dial_mpesa_settings
  end

 

  # POST /dial_mpesa_settings or /dial_mpesa_settings.json
  def create
    # @sms_setting = SmsSetting.find_or_initialize_by(sms_setting_params)
      @dial_mpesa_setting_setting = DialMpesaSetting.find_or_initialize_by(
        consumer_key: params[:consumer_key],
        consumer_secret: params[:consumer_secret],
      ) 
      @dial_mpesa_setting_setting.update(
      # passkey: params[:passkey],
      consumer_key: params[:consumer_key],
        consumer_secret: params[:consumer_secret],
      short_code: params[:short_code],
        account_type: params[:account_type]

    )
      if @dial_mpesa_setting_setting.save
        ActivtyLog.create(action: 'configuration', ip: request.remote_ip,
 description: "Created dial mpesa setting #{@dial_mpesa_setting_setting.short_code}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
        render json: @hotspot_mpesa_setting_setting, status: :created
      else
        render json: @hotspot_mpesa_setting_setting.errors, status: :unprocessable_entity 
      
    end
  end







  # PATCH/PUT /dial_mpesa_settings/1 or /dial_mpesa_settings/1.json
  def update
    respond_to do |format|
      if @dial_mpesa_setting.update(dial_mpesa_setting_params)
        format.html { redirect_to @dial_mpesa_setting, notice: "Dial mpesa setting was successfully updated." }
        format.json { render :show, status: :ok, location: @dial_mpesa_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dial_mpesa_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dial_mpesa_settings/1 or /dial_mpesa_settings/1.json
  def destroy
    @dial_mpesa_setting.destroy!

    respond_to do |format|
      format.html { redirect_to dial_mpesa_settings_path, status: :see_other, notice: "Dial mpesa setting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dial_mpesa_setting
      @dial_mpesa_setting = DialMpesaSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def dial_mpesa_setting_params
      params.require(:dial_mpesa_setting).permit(:account_id, :account_type, :short_code,
       :consumer_key, :consumer_secret, :passkey)
    end
end
