class GeneralSettingsController < ApplicationController
  before_action :set_general_setting, only: %i[ show edit update destroy ]

  set_current_tenant_through_filter

  before_action :set_tenant
before_action :set_time_zone




def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end


def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
  
  
    set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end


  # GET /general_settings or /general_settings.json
  def index
    @general_settings = GeneralSetting.all
    render json: @general_settings
  end

  # GET /general_settings/1 or /general_settings/1.json
  def show
  end

  # GET /general_settings/new
  def new
    @general_setting = GeneralSetting.new
  end

  # GET /general_settings/1/edit
  def edit
  end

  # POST /general_settings or /general_settings.json
  def create
    
    @general_setting = GeneralSetting.first_or_initialize(general_setting_params)
@general_setting.update(general_setting_params)
      if @general_setting.save
        render json: @general_setting, status: :created
      else
        render json: @general_setting.errors, status: :unprocessable_entity 
      
    end
  end

  # PATCH/PUT /general_settings/1 or /general_settings/1.json
  def update
    respond_to do |format|
      if @general_setting.update(general_setting_params)
        format.html { redirect_to @general_setting, notice: "General setting was successfully updated." }
        format.json { render :show, status: :ok, location: @general_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @general_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /general_settings/1 or /general_settings/1.json
  def destroy
    @general_setting.destroy!

    respond_to do |format|
      format.html { redirect_to general_settings_path, status: :see_other, notice: "General setting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_general_setting
      @general_setting = GeneralSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def general_setting_params
      params.require(:general_setting).permit(:title, :timezone, :allowed_ips, :account_id)
    end
end
