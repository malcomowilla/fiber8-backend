class AdSettingsController < ApplicationController
  before_action :set_ad_setting, only: %i[ show edit update destroy ]

  set_current_tenant_through_filter
  before_action :set_tenant
    before_action :update_last_activity


  # GET /ad_settings or /ad_settings.json
  def index
    @ad_settings = AdSetting.all
    render json: @ad_settings
  end





  def update_last_activity
if current_user
      current_user.update!(last_activity_active: Time.current)
    end
    
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



  # GET /ad_settings/1 or /ad_settings/1.json
  def show
  end

  # GET /ad_settings/new
  def new
    @ad_setting = AdSetting.new
  end

  # GET /ad_settings/1/edit
  def edit
  end

  # POST /ad_settings or /ad_settings.json
  def create
    @ad_setting = AdSetting.first_or_initialize(ad_setting_params)
 @ad_setting.update(ad_setting_params)
      if @ad_setting.save
    render json: @ad_setting, status: :created
      else
        render json: @ad_setting.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /ad_settings/1 or /ad_settings/1.json
  def update
    respond_to do |format|
      if @ad_setting.update(ad_setting_params)
        format.html { redirect_to @ad_setting, notice: "Ad setting was successfully updated." }
        format.json { render :show, status: :ok, location: @ad_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ad_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ad_settings/1 or /ad_settings/1.json
  def destroy
    @ad_setting.destroy!

    respond_to do |format|
      format.html { redirect_to ad_settings_path, status: :see_other, notice: "Ad setting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ad_setting
      @ad_setting = AdSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ad_setting_params
      params.require(:ad_setting).permit(:enabled, :to_right, :to_left, :to_top, :account_id)
    end
end
