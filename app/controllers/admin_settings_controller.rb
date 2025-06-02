class AdminSettingsController < ApplicationController
  # before_action :set_admin_setting, only: %i[ show edit update destroy ]


  load_and_authorize_resource except: [:allow_get_admin_settings]
  before_action :update_last_activity
  # GET /admin_settings or /admin_settings.json
  def index
    # @admin_settings = AdminSetting.all
    # render json: @admin_settings
    @admin_settings = AdminSetting.for_user(current_user.id)
  render json: @admin_settings
  end




def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end



def allow_get_admin_settings
  admin = params[:admin_email]
  @admin = User.find_by(email: admin)
  # @admin_settings = AdminSetting.all
  # render json: @admin_settings
  
  admin_settings = AdminSetting.for_user(@admin.id)
  render json: admin_settings
end








  # POST /admin_settings or /admin_settings.json
  def create
    @admin_setting = AdminSetting.first_or_initialize(
      admin_setting_params.merge(

      user: current_user
      )
      )
    @admin_setting.update!(
      admin_setting_params.merge(

      user: current_user
      )
    )
      if @admin_setting.save
         render json: @admin_setting, status: :created
      else
         render json: @admin_setting.errors, status: :unprocessable_entity 
      end
    
  end



  # PATCH/PUT /admin_settings/1 or /admin_settings/1.json
  # def update
  #   respond_to do |format|
  #     if @admin_setting.update(admin_setting_params)
  #       format.html { redirect_to @admin_setting, notice: "Admin setting was successfully updated." }
  #       format.json { render :show, status: :ok, location: @admin_setting }
  #     else
  #       format.html { render :edit, status: :unprocessable_entity }
  #       format.json { render json: @admin_setting.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # DELETE /admin_settings/1 or /admin_settings/1.json
  # def destroy
  #   @admin_setting.destroy!

  #   respond_to do |format|
  #     format.html { redirect_to admin_settings_path, status: :see_other, notice: "Admin setting was successfully destroyed." }
  #     format.json { head :no_content }
  #   end
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_setting
      @admin_setting = AdminSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_setting_params
      params.require(:admin_setting).permit(
        :enable_2fa_for_admin_email,:enable_2fa_for_admin_sms,:send_password_via_sms,
        :send_password_via_email, :enable_2fa_for_admin_passkeys, :check_is_inactive,
        :enable_2fa_google_auth,
:checkinactiveminutes, :checkinactivehrs,:checkinactivedays

      )
    end
end
