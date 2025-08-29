class OnusController < ApplicationController
  before_action :set_onu, only: %i[ show edit update destroy ]


set_current_tenant_through_filter

before_action :set_tenant
before_action :update_last_activity
GENIEACS_HOST = "http://102.221.35.92:7347"


 def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end





def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant  = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end

 

   def reboot
    device_id = params[:id]

    if reboot_device(device_id)
      render json: { message: "Reboot initiated" }, status: :ok
    else
      render json: { message: "Failed to reboot device" }, status: :unprocessable_entity
    end
  end



  def reboot_device(device_id)
    url = URI("#{GENIEACS_HOST}/devices/#{device_id}/tasks?connection_request")

    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request.body = [
      {
        name: "Reboot",
        objectName: "",
        parameterValues: []
      }
    ].to_json

    response = http.request(request)

    response.code.to_i == 200
  
end



  def change_wireless_lan1
  device = Onu.find_by(onu_id: params[:id])
  return render json: { error: "Device not found" }, status: :not_found unless device

  device_id = device.onu_id
  ssid1 = params[:ssid1]
  password1 = params[:wifi_password1]
  standard1 = params[:standard1]
  channel_width1 = params[:channel_width1]
  autochannel1 = params[:autochannel1]
  country_regulatory_domain1 = params[:country_regulatory_domain1]
  tx_power1 = params[:tx_power1]
  authentication_mode1 = params[:authentication_mode1]
  wpa_encryption1 = params[:wpa_encryption1]
  channel = params[:channel]
  ssid_advertisment_enabled1 = params[:ssid_advertisment_enabled1]
  enable1 = params[:enable1]
  radio_enabled1 = params[:radio_enabled1]




  body = {
    name: "setParameterValues",
   parameterValues: [
      ["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSID", ssid1, "xsd:string"],
      ["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.KeyPassphrase", password1, "xsd:string"],
      ["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.Standard", standard1, "xsd:string"],
      ["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.ChannelWidth", channel_width1, "xsd:string"],
      ["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.AutoChannelEnable", autochannel1, "xsd:boolean"],
      ["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.RegulatoryDomain", country_regulatory_domain1, "xsd:string"],
      ["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.IEEE11iEncryptionModes", wpa_encryption1, "xsd:string"],
      ["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.Channel", channel, "xsd:string"],
      ["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.SSIDAdvertisementEnabled", ssid_advertisment_enabled1, "xsd:boolean"],
      ["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.Enable", enable1, "xsd:boolean"],
      ["InternetGatewayDevice.LANDevice.1.WLANConfiguration.1.RadioEnabled", radio_enabled1, "xsd:boolean"]
    ]
  }

  uri = URI("#{GENIEACS_HOST}/devices/#{device_id}/tasks?connection_request")
  request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  request.body = body.to_json

  response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }

  if response.is_a?(Net::HTTPSuccess)
    render json: { message: "WiFi settings updated successfully" }, status: :ok
  else
    render json: { error: "Failed to update WiFi settings" }, status: :unprocessable_entity
  end
end



  # GET /onus or /onus.json
  def index
        get_devices

    @onus = Onu.all
    render json: @onus

  end


def get_device_id
  id = params[:id]
  device = Onu.find_by(id: id)
  render json: device
end



def refresh_devices
  device_record = Onu.find_by(id: params[:id])  # Find the device in DB
  return render json: { message: "No device found" }, status: :not_found if device_record.nil?

  device_id = device_record.onu_id

  # 1. Trigger refresh
  # refresh_result = refresh_device(device_id)
refresh_device(device_id)
  # 2. Wait a bit for GenieACS to update (can be tuned or replaced by async job)
  # sleep 1

  # 3. Fetch the latest data for this device
  device_data = fetch_device_data(device_id)

  if device_data
    # 4. Save the updated attributes
    onu = Onu.find_or_initialize_by(onu_id: device_id)
    onu.update!(extract_device_attributes(device_data))
    render json: onu, serializer: OnuSerializer, status: :ok


    # render json: { message: "Device refreshed successfully", device: onu }, status: :ok
  else
    render json: { message: "Failed to fetch updated data for device #{device_id}" }, status: :bad_request
  end
end



def refresh_device(device_id)
  uri = URI("#{GENIEACS_HOST}/devices/#{device_id}/tasks?connection_request")
  request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  request.body = { name: "refreshObject", objectName: "" }.to_json

  response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
  JSON.parse(response.body) rescue nil
end


  

def fetch_device_data(device_id)
  uri = URI("#{GENIEACS_HOST}/devices/?_id=#{device_id}")
  response = Net::HTTP.get_response(uri)
  return nil unless response.is_a?(Net::HTTPSuccess)

  data = JSON.parse(response.body) rescue nil
  data.is_a?(Array) ? data.first : data  # Take the first element if it's an array
end


def extract_device_attributes(device)
  {
    serial_number: device.dig("_deviceId", "_SerialNumber"),
    oui: device.dig("_deviceId", "_OUI"),
    product_class: device.dig("_deviceId", "_ProductClass"),
    manufacturer: device.dig("_deviceId", "_Manufacturer"),
    last_boot: device["_lastBoot"],
    last_inform: parse_time(device["_lastInform"]),
    ssid1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "SSID", "_value"),
    wlan1_status: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "Status", "_value"),
rf_band1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "X_HW_RFBand", "_value"),
total_associations1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "X_HW_AssociateNum", "_value"),
channel_width1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "X_HW_CurrentOperatingChannelBandwidth", "_value"),

autochannel1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "AutoChannelEnable", "_value"),
    ssid2: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "5", "SSID", "_value"),
     wifi_password1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "PreSharedKey", "1", "KeyPassphrase", "_value"),
        wifi_password2: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "5", "PreSharedKey", "1", "KeyPassphrase", "_value"),
          enable1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "Enable", "_value"),
standard1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "Standard", "_value"),
radio_enabled1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "RadioEnabled", "_value"),
ssid_advertisment_enabled1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "SSIDAdvertisementEnabled", "_value"),
wpa_encryption1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "IEEE11iEncryptionModes", "_value"),
    wan_ip: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "ExternalIPAddress", "_value"),
    mac_adress: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "MACAddress", "_value"),
    dhcp_name: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "Name", "_value"),
    dhcp_addressing_type: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "AddressingType", "_value"),
    dhcp_connection_status: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "ConnectionStatus", "_value"),
    dhcp_uptime: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "Uptime", "_value"),
    dhcp_ip: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "ExternalIPAddress", "_value"),
    dhcp_subnet_mask: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "SubnetMask", "_value"),
    dhcp_gateway: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "DefaultGateway", "_value"),
    dhcp_dns_servers: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "DNSServers", "_value"),
    dhcp_last_connection_error: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "LastConnectionError", "_value"),
    dhcp_mac_address: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "MACAddress", "_value"),
    dhcp_max_mtu_size: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "MaxMTUSize", "_value"),
    dhcp_nat_enabled: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "NATEnabled", "_value"),
    dhcp_vlan_id: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "X_HW_VLAN", "_value"),
    software_version: device.dig("InternetGatewayDevice", "DeviceInfo", "SoftwareVersion", "_value"),
    hardware_version: device.dig("InternetGatewayDevice", "DeviceInfo", "HardwareVersion", "_value"),
    channel: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "Channel", "_value"),
    country_regulatory_domain1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "RegulatoryDomain", "_value"),

    uptime: device.dig("InternetGatewayDevice", "DeviceInfo", "UpTime", "_value"),
    ram_used: device.dig("InternetGatewayDevice", "DeviceInfo", "X_HW_MemUsed", "_value"),
    cpu_used: device.dig("InternetGatewayDevice", "DeviceInfo", "X_HW_CpuUsed", "_value")
  }
end

def get_devices
  genieacs_host = "http://102.221.35.92:7347"
  devices_uri = URI("#{genieacs_host}/devices")

  begin
    # Step 1: Fetch devices first
    response = Net::HTTP.get_response(devices_uri)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("Failed to fetch devices from GenieACS: #{response.code}")
      return render json: [], status: :internal_server_error
    end

   
    updated_response = Net::HTTP.get_response(devices_uri)
    updated_devices = updated_response.is_a?(Net::HTTPSuccess) ? JSON.parse(updated_response.body) : []

    # Step 5: Save/update each device in the DB
    updated_devices.each do |device|
      onu_id = device["_id"]
      onu = Onu.find_or_initialize_by(onu_id: onu_id)

      attributes = {
        serial_number: device.dig("_deviceId", "_SerialNumber"),
        oui: device.dig("_deviceId", "_OUI"),
        product_class: device.dig("_deviceId", "_ProductClass"),
        manufacturer: device.dig("_deviceId", "_Manufacturer"),
        last_boot: device["_lastBoot"],
        last_inform: parse_time(device["_lastInform"]),
        ssid1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "SSID", "_value"),
        ssid2: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "5", "SSID", "_value"),
        enable1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "Enable", "_value"),
        wifi_password1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "PreSharedKey", "1", "KeyPassphrase", "_value"),
        wifi_password2: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "5", "PreSharedKey", "1", "KeyPassphrase", "_value"),
    wlan1_status: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "Status", "_value"),
rf_band1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "X_HW_RFBand", "_value"),
total_associations1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "X_HW_AssociateNum", "_value"),
standard1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "Standard", "_value"),
radio_enabled1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "RadioEnabled", "_value"),
wpa_encryption1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "IEEE11iEncryptionModes", "_value"),
channel: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "Channel", "_value"),
    country_regulatory_domain1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "RegulatoryDomain", "_value"),

ssid_advertisment_enabled1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "SSIDAdvertisementEnabled", "_value"),
channel_width1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "X_HW_CurrentOperatingChannelBandwidth", "_value"),
autochannel1: device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "AutoChannelEnable", "_value"),

        wan_ip: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "ExternalIPAddress", "_value"),
        mac_adress: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "MACAddress", "_value"),
        dhcp_name: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "Name", "_value"),
        dhcp_addressing_type: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "AddressingType", "_value"),
        dhcp_connection_status: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "ConnectionStatus", "_value"),
        dhcp_uptime: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "Uptime", "_value"),
        dhcp_ip: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "ExternalIPAddress", "_value"),
        dhcp_subnet_mask: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "SubnetMask", "_value"),
        dhcp_gateway: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "DefaultGateway", "_value"),
        dhcp_dns_servers: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "DNSServers", "_value"),
        dhcp_last_connection_error: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "LastConnectionError", "_value"),
        dhcp_mac_address: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "MACAddress", "_value"),
        dhcp_max_mtu_size: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "MaxMTUSize", "_value"),
        dhcp_nat_enabled: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "NATEnabled", "_value"),
        dhcp_vlan_id: device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "X_HW_VLAN", "_value"),
        software_version: device.dig("InternetGatewayDevice", "DeviceInfo", "SoftwareVersion", "_value"),
        hardware_version: device.dig("InternetGatewayDevice", "DeviceInfo", "HardwareVersion", "_value"),
        uptime: device.dig("InternetGatewayDevice", "DeviceInfo", "UpTime", "_value"),
        ram_used: device.dig("InternetGatewayDevice", "DeviceInfo", "X_HW_MemUsed", "_value"),
        cpu_used: device.dig("InternetGatewayDevice", "DeviceInfo", "X_HW_CpuUsed", "_value")
      }

      onu.update!(attributes)
    end

  rescue => e
    Rails.logger.error("Error querying GenieACS: #{e.message}")
    # render json: [], status: :internal_server_error
  end
end

def parse_time(value)
  Time.parse(value).in_time_zone("Africa/Nairobi") if value.present?
rescue
  nil
end









  # POST /onus or /onus.json
  def create
    @onu = Onu.new(onu_params)

    respond_to do |format|
      if @onu.save
        format.html { redirect_to @onu, notice: "Onu was successfully created." }
        format.json { render :show, status: :created, location: @onu }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @onu.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /onus/1 or /onus/1.json
  def update
    respond_to do |format|
      if @onu.update(onu_params)
        format.html { redirect_to @onu, notice: "Onu was successfully updated." }
        format.json { render :show, status: :ok, location: @onu }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @onu.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /onus/1 or /onus/1.json
  def destroy
    @onu.destroy!

    respond_to do |format|
      format.html { redirect_to onus_path, status: :see_other, notice: "Onu was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_onu
      @onu = Onu.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def onu_params
      params.require(:onu).permit(:serial_number, :oui, :product_class, :manufacturer, :onu_id, :status, :last_inform, :account_id, :last_boot)
    end
end
