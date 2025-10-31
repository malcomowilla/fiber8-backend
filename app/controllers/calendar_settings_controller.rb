class CalendarSettingsController < ApplicationController
  # before_action :set_calendar_setting, only: %i[ show edit update destroy ]



before_action :update_last_activity

set_current_tenant_through_filter

before_action :set_tenant

# before_action :set_qr_codes






# # application_controller.rb




# def set_qr_codes
      
#     host = request.headers['X-Subdomain']
#     @current_account = Account.find_by(subdomain: host)
  
#       # @current_account = ActsAsTenant.current_tenant
#       qr_codes_dir = Rails.root.join('public', 'qr_codes')
      
#       safe_subdomain = @current_account.subdomain.gsub(/[^\w\-]/, '_')  # Replace invalid characters in the subdomain
#       qr_code_path = qr_codes_dir.join("#{safe_subdomain}_qr_code.png")
    
#       FileUtils.mkdir_p(qr_codes_dir) unless Dir.exist?(qr_codes_dir)
    
#       if File.exist?(qr_code_path)
#         Rails.logger.info "QR code for #{@current_account.subdomain} already exists."
#         @qr_code_url = "/qr_codes/#{safe_subdomain}_qr_code.png"
#       else
#         qr_png = RQRCode::QRCode.new("https://#{request.headers['X-Original-Host']}/client-login", size: 10)
#         png_data = qr_png.as_png(offset: 0, color: '000000', shape_rendering: 'crispEdges', module_size: 10)
    
#         File.open(qr_code_path, 'wb') do |file|
#           file.write(png_data)
#         end
    
#         # Optionally, store the URL for the frontend
#         @qr_code_url = "/qr_codes/#{safe_subdomain}_qr_code.png"
#         Rails.logger.info "QR Code saved to #{qr_code_path}"
#       end
#     end



def set_tenant

  host = request.headers['X-Subdomain'] 
  # Rails.logger.info("Setting tenant for host: #{host}")

  @account = Account.find_by(subdomain: host)
  set_current_tenant(@account)

  unless @account
    render json: { error: 'Invalid tenant' }, status: :not_found
  end
  
end



   def update_last_activity
if current_user
      current_user.update!(last_activity_active: Time.current)
    end
    
  end



  # GET /calendar_settings or /calendar_settings.json
  def index
    @calendar_settings = CalendarSetting.all
    render json: @calendar_settings
  end

  # GET /calendar_settings/1 or /calendar_settings/1.json
  def show
  end

  # GET /calendar_settings/new
  def new
    @calendar_setting = CalendarSetting.new
  end

  # GET /calendar_settings/1/edit
  def edit
  end

  # POST /calendar_settings or /calendar_settings.json
  def create
    @calendar_setting = CalendarSetting.first_or_initialize(calendar_setting_params)
@calendar_setting.update!(calendar_setting_params)
      if @calendar_setting.save
        ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created calendar setting => event starts in  #{@calendar_setting.start_in_hours || @calendar_setting.start_in_minutes}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
        render json: @calendar_setting, status: :created
      else
        render json: @calendar_setting.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /calendar_settings/1 or /calendar_settings/1.json
  def update
    respond_to do |format|
      if @calendar_setting.update(calendar_setting_params)
        format.html { redirect_to @calendar_setting, notice: "Calendar setting was successfully updated." }
        format.json { render :show, status: :ok, location: @calendar_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @calendar_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /calendar_settings/1 or /calendar_settings/1.json
  def destroy
    @calendar_setting.destroy!

    respond_to do |format|
      format.html { redirect_to calendar_settings_path, status: :see_other, notice: "Calendar setting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_calendar_setting
      @calendar_setting = CalendarSetting.find_by(id:params[:id])
    end

    # Only allow a list of trusted parameters through.
    def calendar_setting_params
      params.require(:calendar_setting).permit(:start_in_hours, :start_in_minutes, :account_id)
    end
end
