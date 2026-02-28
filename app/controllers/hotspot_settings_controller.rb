class HotspotSettingsController < ApplicationController
  # before_action :set_hotspot_setting, only: %i[ show edit update destroy ]

  set_current_tenant_through_filter

  before_action :set_tenant
  before_action :update_last_activity
  load_and_authorize_resource :except => [:get_hotspot_setting]
    before_action :set_time_zone
 






def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end


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




#   def upload_hotspot_file
#   require "fileutils"

#   router_ip = params[:router_ip]
#   username  = params[:router_username]
#   password  = params[:router_password]
#   host = request.headers['X-Subdomain']

#   # VPS hotspot directory
#   hotspot_dir = "/root/hotspot"
#   FileUtils.mkdir_p(hotspot_dir)
#   login_file_path = File.join(hotspot_dir, "login.html")

#   # Update login.html dynamically
#   login_html_content = <<~HTML
#     <html>
#       <head><title>Redirecting...</title></head>
#       <body>
#         <script>
#           var mac = "$(mac)";
#           var ip = "$(ip)";
#           var username = "$(username)";
#           window.location.href =
#             "https://#{host}.aitechs.co.ke/hotspot-page?mac=" +
#             mac + "&ip=" + ip + "&username=" + username;
#         </script>
#       </body>
#     </html>
#   HTML

#   File.write(login_file_path, login_html_content)

#   # lftp command: create /hotspot on MikroTik if it doesn't exist
#   command = <<~CMD
#     lftp -d -u #{username},#{password} ftp://#{router_ip} <<EOF
#     set ftp:passive-mode on
#     mkdir -p /hotspot
#     mirror -R --verbose #{hotspot_dir}/ /hotspot
#     bye
#     EOF
#   CMD

#   # Execute command and capture output
#   output = `#{command} 2>&1`

#   render json: {
#     status: "ok",
#     message: "Hotspot directory updated and synced",
#     output: output
#   }
# rescue => e
#   render json: {
#     status: "error",
#     message: e.message,
#     output: e.backtrace
#   }, status: :internal_server_error
# end





  #  def upload_hotspot_file
  #   router_ip = params[:router_ip]
  #   username  = params[:router_username]
  #   password  = params[:router_password]

  #   local_file = "/root/login.html"
    

  #   ftp_commands = <<~FTP
  #     open #{router_ip}
  #     user #{username} #{password}
  #     binary
  #     put #{local_file} hotspot/login.html
  #     bye
  #   FTP

  #   File.write("/tmp/ftp_put.txt", ftp_commands)

  #   output = `ftp -inv < /tmp/ftp_put.txt`

  #   # Detect errors by parsing output
  #   if output.match?(/Not connected|Login failed|530|No such file/i)
  #     render json: {
  #       status: "error",
  #       message: "FTP upload failed",
  #       output: output
  #     }, status: :unprocessable_entity
  #   else
  #     render json: {
  #       status: "ok",
  #       message: "File uploaded successfully",
  #       output: output
  #     }, status: :ok
  #   end
  # end
  # 
  #
  

  def hotspot_setup
    mac = params[:mac]
    version = params[:v]

    render plain: generate_hotspot_script(mac, version),
           content_type: "text/plain"
  end


  



def upload_hotspot_file
  require "tempfile"

 router_ip = params[:router_ip]
  username  = params[:router_username]
  password  = params[:router_password]
  subdomain = request.headers["X-Subdomain"]
  full_domain = request.headers["X-Domain"]  # e.g., "twintech.owitech.co.ke"

  raise "Missing router details" if router_ip.blank? || username.blank? || password.blank?

  # Extract the base domain from X-Domain
  # e.g., "twintech.owitech.co.ke" => "owitech.co.ke"
  # base_domain = full_domain.to_s.split('.').last(2).join('.') if full_domain.present?
base_domain = full_domain.to_s.split('.').last(3).join('.') if full_domain.present?
  # Determine which platform to use
  if base_domain == "owitech.co.ke"
    platform_domain = "owitech.co.ke"
  else
    platform_domain = "aitechs.co.ke"   # fallback
  end


  login_html = <<~HTML
    <html>
      <head>
        <title>Redirecting...</title>
      </head>
      <body>
        <noscript>
          <center><b>JavaScript required</b></center>
        </noscript>

        <script>
          var mac = "$(mac)";
          var ip = "$(ip)";
          var username = "$(username)";

           var redirectUrl = `https://#{subdomain}.#{platform_domain}/hotspot-page?mac=${mac}&ip=${ip}&username=${username}`;


          window.location.href = redirectUrl;
        </script>
      </body>
    </html>
  HTML

  temp_file = Tempfile.new(["login", ".html"])
  temp_file.write(login_html)
  temp_file.close

  ftp_script = <<~FTP
    open #{router_ip}
    user #{username} #{password}
    binary
    put #{temp_file.path} hotspot/login.html
    bye
  FTP

  ftp_file = Tempfile.new("ftp")
  ftp_file.write(ftp_script)
  ftp_file.close

  output = `ftp -inv < #{ftp_file.path} 2>&1`

  temp_file.unlink
  ftp_file.unlink

  if output =~ /(530|550|not connected|failed|denied)/i
    render json: { status: "error", output: output }, status: :unprocessable_entity
  else
    render json: { status: "ok", message: "login.html uploaded", output: output }
  end
rescue => e
  render json: { status: "error", message: e.message }, status: :internal_server_error
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
      voucher_type: @hotspot_settings&.voucher_type,
      voucher_expiration: @hotspot_settings&.voucher_expiration,
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
    voucher_type: @hotspot_settings&.voucher_type,
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
voucher_type: params[:voucher_type],
    
    )

      if @hotspot_setting.update(

    phone_number: params[:phone_number],
    hotspot_name: params[:hotspot_name],
    hotspot_info: params[:hotspot_info],
    hotspot_banner: params[:hotspot_banner],
    email: params[:email],
    voucher_type: params[:voucher_type],
    voucher_expiration: params[:voucher_expiration],
      )
        render json: {

        phone_number: @hotspot_setting.phone_number,
        hotspot_name: @hotspot_setting.hotspot_name,
        hotspot_info: @hotspot_setting.hotspot_info,
        email: @hotspot_setting.email,
        voucher_type: @hotspot_setting.voucher_type,
        voucher_expiration: @hotspot_setting.voucher_expiration,
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


def generate_hotspot_script(mac, version)
    <<~RSC
    /interface bridge add name=bridge-hotspot comment="Owitech Hotspot"
    /interface/bridge/port add interface=ether5 bridge=bridge-hotspot
    /ip pool
    add name=hotspot-pool ranges=10.3.0.2-10.3.0.254 comment="Hotspot IP Pool Owitech"

    /ip address
add address=10.3.0.1/24 comment="hotspot network Owitech" interface=bridge-hotspot
/ip dhcp-server
add address-pool=hotspot-pool disabled=no interface=bridge-hotspot lease-time=40m name=hotspot-dhcp comment="Hotspot DHCP Owitech"

/ip dhcp-server network
add address=10.3.0.0/24 comment="hotspot network Owitech" gateway=10.3.0.1 netmask=255.255.255.0 pool=hotspot-dhcp
    /ip hotspot profile add name=hsprof1 hotspot-address=10.3.0.1

  /ip hotspot add name=hotspot1 interface=bridge-hotspot profile=hsprof1 idle-timeout=00:20:00 keep-alive-timeout=00:20:00 address-pool=hotspot-pool disabled=no comment="Hotspot Owitech"

/ip dns
set allow-remote-requests=yes


    /ip firewall nat add chain=srcnat action=masquerade out-interface=bridge-hotspot

    RSC
  end


    # Only allow a list of trusted parameters through.
    def hotspot_setting_params
      params.permit(:phone_number, :hotspot_name, 
      :hotspot_info, :hotspot_banner, :account_id, :email,
       :voucher_type, :voucher_expiration)
    end
end


