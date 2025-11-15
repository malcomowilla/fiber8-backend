class HotspotMpesaSettingsController < ApplicationController


  load_and_authorize_resource

  set_current_tenant_through_filter


  
  before_action :set_tenant
  # GET /hotspot_mpesa_settings or /hotspot_mpesa_settings.json
  before_action :update_last_activity
 


   def update_last_activity
if current_user
      current_user.update_column(:last_activity_active, Time.now.strftime('%Y-%m-%d %I:%M:%S %p'))
    end
    
  end


  def index
    @hotspot_mpesa_settings =  HotspotMpesaSetting.find_by(account_type: params[:account_type])
    render json: @hotspot_mpesa_settings
  end




#   def customer_mpesa_stk_payments
  
#     raw_data = request.body.read

#     data = JSON.parse(raw_data)
#     Rails.logger.info "Mpesa data: #{data}"
# end



  def customer_mpesa_stk_payments
    # Raw request body (as a string)
    raw_data = request.body.read

    # Parse JSON if it's JSON-formatted
    data = JSON.parse(raw_data) rescue {}

    Rails.logger.info "M-Pesa Callback Received: #{data}"

    # Example: extract fields
    merchant_request_id = data.dig("Body", "stkCallback", "MerchantRequestID")
    result_code = data.dig("Body", "stkCallback", "ResultCode")
    result_desc = data.dig("Body", "stkCallback", "ResultDesc")

    

    # Process the payment based on result
    if result_code == 0
      # Success — update your database, mark as paid, etc.
    else
      # Failed transaction
    end

    head :ok  # Always respond 200 OK to M-Pesa
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
        ActivtyLog.create(action: 'configuration', ip: request.remote_ip,
 description: "Created hotspot mpesa setting #{@hotspot_mpesa_setting_setting.short_code}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
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
