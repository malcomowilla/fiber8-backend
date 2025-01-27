class RouterSettingsController < ApplicationController
  # before_action :set_router_setting, only: %i[ show edit update destroy ]

  # GET /router_settings or /router_settings.json
  def index
    @router_settings = RouterSetting.all
    render json: @router_settings
  end

  # POST /router_settings or /router_settings.json
  def create
    @router_setting = RouterSetting.first_or_initialize(router_setting_params)
    @router_setting.update(router_setting_params)
      if @router_setting.save
        render json: @router_setting, status: :created
      else
       render json: @router_setting.errors, status: :unprocessable_entity 
      
    end
  end


  def allow_get_router_settings
    @router_settings = RouterSetting.all
    render json: @router_settings
  end
  # PATCH/PUT /router_settings/1 or /router_settings/1.json
 

  # # DELETE /router_settings/1 or /router_settings/1.json
  # def destroy
  #   @router_setting.destroy!

  #   respond_to do |format|
  #     format.html { redirect_to router_settings_url, notice: "Router setting was successfully destroyed." }
  #     format.json { head :no_content }
  #   end
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_router_setting
      @router_setting = RouterSetting.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def router_setting_params
      params.require(:router_setting).permit(:router_name)
    end
end
