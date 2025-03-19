class DialUpMpesaSettingsController < ApplicationController
  before_action :set_dial_up_mpesa_setting, only: %i[ show edit update destroy ]

  # GET /dial_up_mpesa_settings or /dial_up_mpesa_settings.json
  def index
    @dial_up_mpesa_settings = DialUpMpesaSetting.all
  end

  # GET /dial_up_mpesa_settings/1 or /dial_up_mpesa_settings/1.json
  def show
  end

  # GET /dial_up_mpesa_settings/new
  def new
    @dial_up_mpesa_setting = DialUpMpesaSetting.new
  end

  # GET /dial_up_mpesa_settings/1/edit
  def edit
  end

  # POST /dial_up_mpesa_settings or /dial_up_mpesa_settings.json
  def create
    @dial_up_mpesa_setting = DialUpMpesaSetting.new(dial_up_mpesa_setting_params)

    respond_to do |format|
      if @dial_up_mpesa_setting.save
        format.html { redirect_to @dial_up_mpesa_setting, notice: "Dial up mpesa setting was successfully created." }
        format.json { render :show, status: :created, location: @dial_up_mpesa_setting }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @dial_up_mpesa_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dial_up_mpesa_settings/1 or /dial_up_mpesa_settings/1.json
  def update
    respond_to do |format|
      if @dial_up_mpesa_setting.update(dial_up_mpesa_setting_params)
        format.html { redirect_to @dial_up_mpesa_setting, notice: "Dial up mpesa setting was successfully updated." }
        format.json { render :show, status: :ok, location: @dial_up_mpesa_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @dial_up_mpesa_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dial_up_mpesa_settings/1 or /dial_up_mpesa_settings/1.json
  def destroy
    @dial_up_mpesa_setting.destroy!

    respond_to do |format|
      format.html { redirect_to dial_up_mpesa_settings_path, status: :see_other, notice: "Dial up mpesa setting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dial_up_mpesa_setting
      @dial_up_mpesa_setting = DialUpMpesaSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def dial_up_mpesa_setting_params
      params.require(:dial_up_mpesa_setting).permit(:account_type, :short_code, :consumer_key, :consumer_secret, :passkey)
    end
end
