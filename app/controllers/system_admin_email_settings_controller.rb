class SystemAdminEmailSettingsController < ApplicationController
  before_action :set_system_admin_email_setting, only: %i[ show edit update destroy ]

  # GET /system_admin_email_settings or /system_admin_email_settings.json
  def index
    @system_admin_email_settings = SystemAdminEmailSetting.all
  end

  # GET /system_admin_email_settings/1 or /system_admin_email_settings/1.json
  def show
  end

  # GET /system_admin_email_settings/new
  def new
    @system_admin_email_setting = SystemAdminEmailSetting.new
  end

  # GET /system_admin_email_settings/1/edit
  def edit
  end

  # POST /system_admin_email_settings or /system_admin_email_settings.json
  def create
    @system_admin_email_setting = SystemAdminEmailSetting.new(system_admin_email_setting_params)

    respond_to do |format|
      if @system_admin_email_setting.save
        format.html { redirect_to system_admin_email_setting_url(@system_admin_email_setting), notice: "System admin email setting was successfully created." }
        format.json { render :show, status: :created, location: @system_admin_email_setting }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @system_admin_email_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /system_admin_email_settings/1 or /system_admin_email_settings/1.json
  def update
    respond_to do |format|
      if @system_admin_email_setting.update(system_admin_email_setting_params)
        format.html { redirect_to system_admin_email_setting_url(@system_admin_email_setting), notice: "System admin email setting was successfully updated." }
        format.json { render :show, status: :ok, location: @system_admin_email_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @system_admin_email_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /system_admin_email_settings/1 or /system_admin_email_settings/1.json
  def destroy
    @system_admin_email_setting.destroy!

    respond_to do |format|
      format.html { redirect_to system_admin_email_settings_url, notice: "System admin email setting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_system_admin_email_setting
      @system_admin_email_setting = SystemAdminEmailSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def system_admin_email_setting_params
      params.require(:system_admin_email_setting).permit(:smtp_host, :smtp_username, :sender_email, :smtp_password, :api_keydomain, :system_admin_id)
    end
end
