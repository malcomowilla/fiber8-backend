class HotspotSettingsController < ApplicationController
  # before_action :set_hotspot_setting, only: %i[ show edit update destroy ]

  set_current_tenant_through_filter

  before_action :set_tenant
  before_action :update_last_activity
  load_and_authorize_resource :except => [:get_hotspot_setting]
  # GET /hotspot_settings or /hotspot_settings.json
  # 






 def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end




  def set_tenant

    host = request.headers['X-Subdomain'] 
    Rails.logger.info("Setting tenant for host: #{host}")
  
    @account = Account.find_by(subdomain: host)
    set_current_tenant(@account)
  
    unless @account
      render json: { error: 'Invalid tenant' }, status: :not_found
    end
    
  end


   def upload_hotspot_file
    router_ip = params[:router_ip]
    username  = params[:router_username]
    password  = params[:router_password]

    local_file = "/root/login.html"

    ftp_commands = <<~FTP
      open #{router_ip}
      user #{username} #{password}
      binary
      put #{local_file} hotspot/login.html
      bye
    FTP

    File.write("/tmp/ftp_put.txt", ftp_commands)

    output = `ftp -inv < /tmp/ftp_put.txt`

    # Detect errors by parsing output
    if output.match?(/Not connected|Login failed|530|No such file/i)
      render json: {
        status: "error",
        message: "FTP upload failed",
        output: output
      }, status: :unprocessable_entity
    else
      render json: {
        status: "ok",
        message: "File uploaded successfully",
        output: output
      }, status: :ok
    end
  end



  def index
    # @hotspot_settings = HotspotSetting.all
    # render json: @hotspot_settings
    # 
    #
    #
    #
    #
    @account = ActsAsTenant.current_tenant
    @hotspot_settings = @account.hotspot_setting
    render json: {
      phone_number: @hotspot_settings&.phone_number,
      hotspot_name: @hotspot_settings&.hotspot_name,
      hotspot_info: @hotspot_settings&.hotspot_info,
      email: @hotspot_settings&.email,
      hotspot_banner: @hotspot_settings&.hotspot_banner&.attached? ? 
      # rails_blob_url(@hotspot_settings.hotspot_banner, host: '8209-102-221-35-92.ngrok-free.app', protocol: 'https', port: nil) : nil
      # }, 
      #   hotspot_banner: @hotspot_settings&.hotspot_banner&.attached? ? 
      rails_blob_url(@hotspot_settings.hotspot_banner, host: 'localhost', protocol: 'http', port: 4000) : nil
    }

      
  end

def get_hotspot_setting
  
  @account = ActsAsTenant.current_tenant
  @hotspot_settings = @account.hotspot_setting
  render json: {
    phone_number: @hotspot_settings&.phone_number,
    hotspot_name: @hotspot_settings&.hotspot_name,
    hotspot_info: @hotspot_settings&.hotspot_info,
    email: @hotspot_settings&.email,
    hotspot_banner: @hotspot_settings&.hotspot_banner&.attached? ? 
    # rails_blob_url(@hotspot_settings.hotspot_banner, host: '8209-102-221-35-92.ngrok-free.app', protocol: 'https', port: nil) : nil
    # }, 
    #   hotspot_banner: @hotspot_settings&.hotspot_banner&.attached? ? 
    rails_blob_url(@hotspot_settings.hotspot_banner, host: 'localhost', protocol: 'http', port: 4000) : nil
  }
end

  



  # POST /hotspot_settings or /hotspot_settings.json
  def create
    @hotspot_setting = HotspotSetting.first_or_initialize(
      
    
    phone_number: params[:phone_number],
hotspot_name: params[:hotspot_name],
hotspot_info: params[:hotspot_info],
hotspot_banner: params[:hotspot_banner],
email: params[:email],
    
    )

      if @hotspot_setting.update(

    phone_number: params[:phone_number],
    hotspot_name: params[:hotspot_name],
    hotspot_info: params[:hotspot_info],
    hotspot_banner: params[:hotspot_banner],
    email: params[:email],
      )
        render json: {

        phone_number: @hotspot_setting.phone_number,
        hotspot_name: @hotspot_setting.hotspot_name,
        hotspot_info: @hotspot_setting.hotspot_info,
        email: @hotspot_setting.email,
        hotspot_banner: @hotspot_setting.hotspot_banner.attached? ? 
        # rails_blob_url(@hotspot_setting.hotspot_banner, host: 'speeches-air-una-dolls.trycloudflare.com', protocol: 'https', port: nil) : nil
        # }, 
        #   hotspot_banner: @hotspot_setting.hotspot_banner.attached? ? 
        rails_blob_url(@hotspot_setting.hotspot_banner, host: 'localhost', protocol: 'http', port: 4000) : nil
      }, 
        
        status: :created
      else
         render json: @hotspot_setting.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /hotspot_settings/1 or /hotspot_settings/1.json
  def update
    respond_to do |format|
      if @hotspot_setting.update(hotspot_setting_params)
        format.html { redirect_to @hotspot_setting, notice: "Hotspot setting was successfully updated." }
        format.json { render :show, status: :ok, location: @hotspot_setting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @hotspot_setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hotspot_settings/1 or /hotspot_settings/1.json
  

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_setting
      @hotspot_setting = HotspotSetting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def hotspot_setting_params
      params.permit(:phone_number, :hotspot_name, 
      :hotspot_info, :hotspot_banner, :account_id, :email)
    end
end
