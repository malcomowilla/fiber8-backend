class OnusController < ApplicationController
  before_action :set_onu, only: %i[ show edit update destroy ]


set_current_tenant_through_filter

before_action :set_tenant
before_action :update_last_activity


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

 

  # GET /onus or /onus.json
  def index
        get_devices

    @onus = Onu.all
    render json: @onus

  end


def get_devices
  uri = URI("http://102.221.35.92:7347/devices")

  begin
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      devices = JSON.parse(response.body)

      devices.each do |device|
        onu_id = device["_id"]
        Onu.find_or_initialize_by(onu_id: onu_id).tap do |onu|
          onu.serial_number = device.dig("_deviceId", "_SerialNumber")
          onu.oui = device.dig("_deviceId", "_OUI")
          onu.product_class = device.dig("_deviceId", "_ProductClass")
          onu.manufacturer = device.dig("_deviceId", "_Manufacturer")
          onu.last_boot = device["_lastBoot"]
          onu.last_inform = Time.parse(device["_lastInform"]).in_time_zone("Africa/Nairobi")
          onu.ssid1 = device["InternetGatewayDevice"]["LANDevice"]["1"]["WLANConfiguration"]["1"]["SSID"]["_value"]
          onu.ssid2 = device["InternetGatewayDevice"]["LANDevice"]["1"]["WLANConfiguration"]["5"]["SSID"]["_value"]
          wan_ip = device["InternetGatewayDevice"]["WANDevice"]["1"]["WANConnectionDevice"]["1"]["WANIPConnection"]["1"]["ExternalIPAddress"]["_value"]
          onu.wan_ip = wan_ip
 onu.mac_adress = device["InternetGatewayDevice"]["WANDevice"]["1"]["WANConnectionDevice"]["1"]["WANIPConnection"]["1"]["MACAddress"]["_value"]

          # onu.status = device["_registered"] ? "registered" : "unregistered"


          onu.save!
        end
      end

      # render json: { message: "Devices fetched and saved successfully", count: devices.size }
    else
      Rails.logger.error("Failed to fetch devices from GenieACS: #{response.code}")
      render json: [], status: :internal_server_error
    end
  rescue => e
    Rails.logger.error("Error querying GenieACS: #{e.message}")
    render json: [], status: :internal_server_error
  end
end

  
  # GET /onus/1 or /onus/1.json
  def show
  end

  # GET /onus/new
  def new
    @onu = Onu.new
  end

  # GET /onus/1/edit
  def edit
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
