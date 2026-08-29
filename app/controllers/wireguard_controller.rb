



# class WireguardController < ApplicationController
#   require 'securerandom'
#   require 'open3'
#   require 'ipaddr'

#   WG_CONFIG_PATH = "/etc/wireguard/wg0.conf"


# before_action :update_last_activity
# before_action :set_tenant

# before_action :set_time_zone





#  def set_time_zone
#   Rails.logger.info "Setting time zone"
#   Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
#     Rails.logger.info "Setting time zone #{Time.zone}"

# end


#    def update_last_activity
# if current_user
#       current_user.update!(last_activity_active: Time.current)
#     end
    
#   end





# def set_tenant
#     host = request.headers['X-Subdomain']
#     @account = Account.find_by(subdomain: host)
#      ActsAsTenant.current_tenant = @account
#     EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  
#   rescue ActiveRecord::RecordNotFound
#     render json: { error: 'Invalid tenant' }, status: :not_found
  
#   end





# def provision_router
#   router = NasRouter.find(params[:router_id])
  
#   # SSH into router using its WireGuard IP and push the API user creation command
#   Net::SSH.start(router.ip_address, 'admin', password: '') do |ssh|
#     ssh.exec!("/user add name=#{router.username} password=#{router.password} group=full")
   
#     ssh.exec!("/tool fetch url=https://#{request.host}/api/mikrotik_callback address=#{router.ip_address}")
#   end
  
#   render json: { success: true }
# rescue => e
#   render json: { error: e.message }, status: :unprocessable_entity
# end









#   def generate_config
#     authorize! :generate_config, WireguardPeer
#   host = request.headers['X-Subdomain']

#   if host == 'demo'
#     render json: { error: 'demo mode does not allow wireguard config generation' }, status: :bad_request
#     return
#   end

#   network_address = params[:network_address] || "10.2.0.0"
#   subnet_mask = params[:subnet_mask] || "24"
#   client_ip = params[:client_ip]

#   # Validate network address
#   begin
#     network = IPAddr.new("#{network_address}/#{subnet_mask}")
#   rescue IPAddr::InvalidAddressError => e
#     render json: { error: "Invalid network address: #{e.message}" }, status: :bad_request
#     return
#   end

#   client_private_key, _ = Open3.capture3("wg genkey")
#   client_private_key.strip!
#   client_public_key, _ = Open3.capture3("echo #{client_private_key} | wg pubkey")
#   client_public_key.strip!

#   server_public_key, _ = Open3.capture3("wg show wg0 public-key")
#   server_public_key.strip!

#   assigned_ip = if client_ip.present?
#     begin
#       client_ip_obj = IPAddr.new(client_ip)
#       unless network.include?(client_ip_obj)
#         render json: { error: "Specified IP #{client_ip} is not in network #{network_address}/#{subnet_mask}" }, status: :bad_request
#         return
#       end
#       "#{client_ip}/#{subnet_mask}"
#     rescue IPAddr::InvalidAddressError => e
#       render json: { error: "Invalid client IP: #{e.message}" }, status: :bad_request
#       return
#     end
#   else
#     host_range = network.to_range
#     random_ip = host_range.to_a[1..-2].sample || host_range.first.succ
#     "#{random_ip}/#{subnet_mask}"
#   end

#   ip_range = network.to_range
#   server_ip = ip_range.first.succ.to_s

#   WireguardPeer.create!(
#     public_key: client_public_key,
#     allowed_ips: "#{random_ip}/32"
#   )

# api_username = "owitech_#{SecureRandom.hex(4)}"
# api_password = SecureRandom.hex(12)

# router = NasRouter.create!(
#   name:       params[:identity].presence || "MK-#{api_username}",
#   ip_address: random_ip.to_s,   # the WireGuard tunnel IP
#   username:   api_username,
#   password:   api_password,
#   location:   params[:location],
#   api_username:     api_username,
#   api_password:     api_password,
 
# )
# router.update(
#    router_id:        router.id,
#   router_ip:        random_ip.to_s,
# )

#   mikrotik_config = generate_mikrotik_config(client_private_key, server_public_key, assigned_ip)
#   server_config = generate_server_config(client_public_key, assigned_ip)

#   # Apply peer directly using `wg set`
#   begin
#     system("wg set wg0 peer #{client_public_key} allowed-ips #{random_ip}/32")
#   rescue => e
#     render json: { error: "Failed to apply peer to wg0: #{e.message}" }, status: :internal_server_error
#     return
#   end

#   render json: {
#     mikrotik_config: mikrotik_config,
#     server_config: server_config,
#     client_ip: assigned_ip,
#     server_ip: server_ip,
#     network: "#{network_address}/#{subnet_mask}",
#     private_key: client_private_key,
#     public_key: client_public_key,
#   api_username:     api_username,
#   api_password:     api_password,
#   router_id:        router.id,
#   router_ip:        random_ip.to_s,
#   }
# end






# def check_peer
#     public_key = params[:public_key]

#     result = Wireguard::PeerCheck.new.call(public_key)

#     if result[:error]
#       render json: result, status: :unprocessable_entity
#     else
#       render json: result, status: :ok
#     end
#   end


# def generate_wireguard_app_config
#  host = request.headers['X-Subdomain']

#   if host == 'demo'
#     render json: { error: 'demo mode does not allow wireguard config generation' }, status: :bad_request
#     return
#   end

#   network_address =  "10.2.0.0"
#   subnet_mask = "24"

#   # Validate network address
#   begin
#     network = IPAddr.new("#{network_address}/#{subnet_mask}")
#   rescue IPAddr::InvalidAddressError => e
#     render json: { error: "Invalid network address: #{e.message}" }, status: :bad_request
#     return
#   end

#   client_private_key, _ = Open3.capture3("wg genkey")
#   client_private_key.strip!
#   client_public_key, _ = Open3.capture3("echo #{client_private_key} | wg pubkey")
#   client_public_key.strip!

#   # Get server public key
#   server_public_key, _ = Open3.capture3("wg show wg0 public-key")
#   server_public_key.strip!
#     network = IPAddr.new("#{network_address}/#{subnet_mask}")

#     host_range = network.to_range
#     random_ip = host_range.to_a[1..-2].sample || host_range.first.succ
  
# WireguardPeer.create(
#     public_key: client_public_key,
#     # allowed_ips: assigned_ip
#     allowed_ips: "#{random_ip}/32"
#   )
#   # Assign client IP

  
# client_config = <<~WGCONFIG
#   [Interface]
#   PrivateKey = #{client_private_key}
#   Address = #{random_ip}/32

#   [Peer]
#   PublicKey = #{server_public_key}
#   Endpoint = 13.50.245.40:51820
#   AllowedIPs = 0.0.0.0/0
# WGCONFIG



# qr = RQRCode::QRCode.new(client_config)
# png = qr.as_png(size: 300)

# # Convert to base64 for easy display in frontend or API
# qr_base64 = Base64.strict_encode64(png.to_s)

#  render json: {
#   random_ip: random_ip,
#         qr_code_data_url: "data:image/png;base64,#{qr_base64}",
#       }
# end


#   private








#   def generate_mikrotik_config(private_key, server_pubkey, ip)
#     <<~CONFIG
#       /interface wireguard add name=wireguard1 private-key="#{private_key}"
      
 
#         /ip route add dst-address=10.2.0.1/32 gateway=wireguard1

#        /interface wireguard peers
#    add allowed-address=0.0.0.0/0 endpoint-address=13.50.245.40 endpoint-port=51820 interface=wireguard1 persistent-keepalive=25s public-key="#{server_pubkey}"

#       /ip address add address=#{ip} interface=wireguard1

#       /ip firewall filter
#       add chain=input src-address=10.2.0.1 protocol=icmp action=accept comment="Allow Wireguard Server To Ping"
      
#       add chain=input src-address=#{ip} protocol=tcp action=accept comment="Allow Wireguard Client Mikrotik"
      
#       add chain=input src-address=10.2.0.1 protocol=tcp dst-port=22,80 action=accept comment="Allow Wireguard Server"

#       add chain=input src-address=10.2.0.0/24 protocol=tcp action=drop comment="Block all other wireguard clients"

#       add chain=input action=drop protocol=tcp src-address=!10.2.0.1 dst-port=21,22,23 log=yes log-prefix="drop, ssh,telnet" comment="Drop ssh telnet if not from wireguard server"

      
    
#     CONFIG
#   end

#   def generate_server_config(client_pubkey, ip)
#     <<~CONFIG
#       # Add this to your WireGuard server config (/etc/wireguard/wg0.conf)
#       [Peer]
#       PublicKey = #{client_pubkey}
#       AllowedIPs = #{ip}
#       # PersistentKeepalive = 25 (uncomment if client is behind NAT)
#     CONFIG
#   end
# end


class WireguardController < ApplicationController
  require 'securerandom'
  require 'open3'
  require 'ipaddr'

  WG_CONFIG_PATH = "/etc/wireguard/wg0.conf"

  before_action :update_last_activity
  before_action :set_tenant
  before_action :set_time_zone

  def set_time_zone
    Rails.logger.info "Setting time zone"
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"
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
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # POST /api/wireguard/provision_router
  #
  # Previously this SSHed into the router as `admin` with a blank
  # password to create the API user remotely. That only works on a
  # router that still has no admin password set — a real security gap
  # on its own, and fragile (nothing stops a factory-reset router or a
  # changed password from silently breaking onboarding).
  #
  # The admin already pastes the "API User & RADIUS" script into the
  # router's terminal by hand (step 2 of the onboarding wizard), which
  # creates the api_username/api_password user and enables the REST
  # API. So instead of pushing config ourselves, we just verify that
  # script was applied by hitting the REST API with the credentials
  # generate_config already created and stored on the NasRouter record.
  def provision_router
    router = NasRouter.find(params[:router_id])

    response = RestClient::Request.execute(
      method: :get,
      url: "http://#{router.ip_address}/rest/system/identity",
      user: router.api_username,
      password: router.api_password,
      timeout: 5,
      open_timeout: 3
    )

    if response.code == 200
      router.update!(provisioned: true, provisioned_at: Time.current)
      render json: { success: true }
    else
      render json: { error: "Unexpected response from router (#{response.code})" }, status: :unprocessable_entity
    end
  rescue RestClient::Unauthorized
    render json: {
      error: "API credentials rejected — make sure the API User & RADIUS script was pasted into the router's terminal"
    }, status: :unprocessable_entity
  rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    Rails.logger.warn "provision_router: #{router&.ip_address} unreachable (#{e.class})"
    render json: {
      error: "Router not reachable over REST API yet — has the API User & RADIUS script been applied?"
    }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Router not found' }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def generate_config
    authorize! :generate_config, WireguardPeer
    host = request.headers['X-Subdomain']

    if host == 'demo'
      render json: { error: 'demo mode does not allow wireguard config generation' }, status: :bad_request
      return
    end

    network_address = params[:network_address] || "10.2.0.0"
    subnet_mask = params[:subnet_mask] || "24"
    client_ip = params[:client_ip]

    begin
      network = IPAddr.new("#{network_address}/#{subnet_mask}")
    rescue IPAddr::InvalidAddressError => e
      render json: { error: "Invalid network address: #{e.message}" }, status: :bad_request
      return
    end

    client_private_key, _ = Open3.capture3("wg genkey")
    client_private_key.strip!
    client_public_key, _ = Open3.capture3("echo #{client_private_key} | wg pubkey")
    client_public_key.strip!

    server_public_key, _ = Open3.capture3("wg show wg0 public-key")
    server_public_key.strip!

    assigned_ip = if client_ip.present?
      begin
        client_ip_obj = IPAddr.new(client_ip)
        unless network.include?(client_ip_obj)
          render json: { error: "Specified IP #{client_ip} is not in network #{network_address}/#{subnet_mask}" }, status: :bad_request
          return
        end
        "#{client_ip}/#{subnet_mask}"
      rescue IPAddr::InvalidAddressError => e
        render json: { error: "Invalid client IP: #{e.message}" }, status: :bad_request
        return
      end
    else
      host_range = network.to_range
      random_ip = host_range.to_a[1..-2].sample || host_range.first.succ
      "#{random_ip}/#{subnet_mask}"
    end

    ip_range = network.to_range
    server_ip = ip_range.first.succ.to_s

    WireguardPeer.create!(
      public_key: client_public_key,
      allowed_ips: "#{random_ip}/32"
    )

    api_username = "owitech_#{SecureRandom.hex(4)}"
    api_password = SecureRandom.hex(12)

    router = NasRouter.create!(
      name:       params[:identity].presence || "MK-#{api_username}",
      ip_address: random_ip.to_s,
      username:   api_username,
      password:   api_password,
      location:   params[:location],
      api_username: api_username,
      api_password: api_password
    )
    router.update(
      router_id: router.id,
      router_ip: random_ip.to_s
    )

    mikrotik_config = generate_mikrotik_config(client_private_key, server_public_key, assigned_ip)
    server_config = generate_server_config(client_public_key, assigned_ip)

    begin
      system("wg set wg0 peer #{client_public_key} allowed-ips #{random_ip}/32")
    rescue => e
      render json: { error: "Failed to apply peer to wg0: #{e.message}" }, status: :internal_server_error
      return
    end

    render json: {
      mikrotik_config: mikrotik_config,
      server_config: server_config,
      client_ip: assigned_ip,
      server_ip: server_ip,
      network: "#{network_address}/#{subnet_mask}",
      private_key: client_private_key,
      public_key: client_public_key,
      api_username: api_username,
      api_password: api_password,
      router_id: router.id,
      router_ip: random_ip.to_s
    }
  end

  def check_peer
    public_key = params[:public_key]
    result = Wireguard::PeerCheck.new.call(public_key)

    if result[:error]
      render json: result, status: :unprocessable_entity
    else
      render json: result, status: :ok
    end
  end

  def generate_wireguard_app_config
    host = request.headers['X-Subdomain']

    if host == 'demo'
      render json: { error: 'demo mode does not allow wireguard config generation' }, status: :bad_request
      return
    end

    network_address = "10.2.0.0"
    subnet_mask = "24"

    begin
      network = IPAddr.new("#{network_address}/#{subnet_mask}")
    rescue IPAddr::InvalidAddressError => e
      render json: { error: "Invalid network address: #{e.message}" }, status: :bad_request
      return
    end

    client_private_key, _ = Open3.capture3("wg genkey")
    client_private_key.strip!
    client_public_key, _ = Open3.capture3("echo #{client_private_key} | wg pubkey")
    client_public_key.strip!

    server_public_key, _ = Open3.capture3("wg show wg0 public-key")
    server_public_key.strip!

    network = IPAddr.new("#{network_address}/#{subnet_mask}")
    host_range = network.to_range
    random_ip = host_range.to_a[1..-2].sample || host_range.first.succ

    WireguardPeer.create(
      public_key: client_public_key,
      allowed_ips: "#{random_ip}/32"
    )

    client_config = <<~WGCONFIG
      [Interface]
      PrivateKey = #{client_private_key}
      Address = #{random_ip}/32

      [Peer]
      PublicKey = #{server_public_key}
      Endpoint = 13.50.245.40:51820
      AllowedIPs = 0.0.0.0/0
    WGCONFIG

    qr = RQRCode::QRCode.new(client_config)
    png = qr.as_png(size: 300)
    qr_base64 = Base64.strict_encode64(png.to_s)

    render json: {
      random_ip: random_ip,
      qr_code_data_url: "data:image/png;base64,#{qr_base64}"
    }
  end

  private

  def generate_mikrotik_config(private_key, server_pubkey, ip)
    <<~CONFIG
      /interface wireguard add name=wireguard1 private-key="#{private_key}"

      /ip route add dst-address=10.2.0.1/32 gateway=wireguard1

      /interface wireguard peers
      add allowed-address=0.0.0.0/0 endpoint-address=13.50.245.40 endpoint-port=51820 interface=wireguard1 persistent-keepalive=25s public-key="#{server_pubkey}"

      /ip address add address=#{ip} interface=wireguard1

      /ip firewall filter
      add chain=input src-address=10.2.0.1 protocol=icmp action=accept comment="Allow Wireguard Server To Ping"

      add chain=input src-address=#{ip} protocol=tcp action=accept comment="Allow Wireguard Client Mikrotik"

      add chain=input src-address=10.2.0.1 protocol=tcp dst-port=22,80 action=accept comment="Allow Wireguard Server"

      add chain=input src-address=10.2.0.0/24 protocol=tcp action=drop comment="Block all other wireguard clients"

      add chain=input action=drop protocol=tcp src-address=!10.2.0.1 dst-port=21,22,23 log=yes log-prefix="drop, ssh,telnet" comment="Drop ssh telnet if not from wireguard server"
    CONFIG
  end



  def generate_server_config(client_pubkey, ip)
    <<~CONFIG
      # Add this to your WireGuard server config (/etc/wireguard/wg0.conf)
      [Peer]
      PublicKey = #{client_pubkey}
      AllowedIPs = #{ip}
      # PersistentKeepalive = 25 (uncomment if client is behind NAT)
    CONFIG
  end
end