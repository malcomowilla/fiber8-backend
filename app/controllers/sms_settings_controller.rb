class SmsSettingsController < ApplicationController
  # before_action :set_sms_setting, only: %i[ show edit update destroy ]
  load_and_authorize_resource

  # GET /sms_settings or /sms_settings.json
  # 

  set_current_tenant_through_filter


  
  before_action :set_tenant
  def index
    Rails.logger.info "current tenant sms settin: #{ActsAsTenant.current_tenant.sms_setting.sms_provider}"
    @sms_settings = SmsSetting.find_by(sms_provider: params[:provider])

    render json: @sms_settings
  end





  def saved_sms_settings
    
    # @sms_settings = SmsSetting.all
    # render json: @sms_settings
    @sms_settings = SmsSetting.order(updated_at: :desc)
  render json: @sms_settings
  end

  def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
  
  
    set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
   end

  # api key =>c3I6A1BuUvESuTkdSa2l
  # api secret => aSYTHMEmRF3XQUUSPANeYGEeGlZYTYGYFj4TXWqV
  # POST /sms_settings or /sms_settings.json
  def create
    # @sms_setting = SmsSetting.find_or_initialize_by(sms_setting_params)
      @sms_setting = SmsSetting.find_or_initialize_by(
        api_secret: params[:api_secret],
        api_key: params[:api_key],
      ) 
    @sms_setting.update(
      api_key: params[:api_key],
      api_secret: params[:api_secret],
      sender_id: params[:sender_id],
      short_code: params[:short_code],
      sms_provider: params[:sms_provider],
      partnerID: params[:partnerID]

    )
      if  @sms_setting.save 
        render json: @sms_setting, status: :created
      else
        render json: @sms_setting.errors, status: :unprocessable_entity 
      
    end
  end

  # PATCH/PUT /sms_settings/1 or /sms_settings/1.json
  # def update
  #   respond_to do |format|
  #     if @sms_setting.update(sms_setting_params)
  #       format.html { redirect_to sms_setting_url(@sms_setting), notice: "Sms setting was successfully updated." }
  #       format.json { render :show, status: :ok, location: @sms_setting }
  #     else
  #       format.html { render :edit, status: :unprocessable_entity }
  #       format.json { render json: @sms_setting.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # DELETE /sms_settings/1 or /sms_settings/1.json
  # def destroy
  #   @sms_setting.destroy!

  #   respond_to do |format|
  #     format.html { redirect_to sms_settings_url, notice: "Sms setting was successfully destroyed." }
  #     format.json { head :no_content }
  #   end
  # end

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
