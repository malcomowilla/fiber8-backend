class AcsTestingController < ApplicationController


 def index
    uri = URI("http://102.221.35.92:7347/devices") # Update host/port if needed

    
    begin
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
       
        @devices = JSON.parse(response.body)
        render json:  @devices.map { |device| device["InternetGatewayDevice"]["LANDevice"]["1"]["WLANConfiguration"]["1"]["RegulatoryDomain"]["_value"] }
# render json:  @devices.map { |device| device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1", "Standard",  ) }
    # device.dig("InternetGatewayDevice", "LANDevice", "1", "WLANConfiguration", "1")


 
      else
        Rails.logger.error("Failed to fetch devices from GenieACS: #{response.code}")
        render json: @devices, status: :internal_server_error
      end
    rescue => e
      @devices = []
      Rails.logger.error("Error querying GenieACS: #{e.message}")
      render json: @devices, status: :internal_server_error
    end
  end






    
# def index
#   genieacs_host = "http://102.221.35.92:7347"

#   begin
#     # Step 1: Fetch all devices first
#     devices_uri = URI("#{genieacs_host}/devices")
#     response = Net::HTTP.get_response(devices_uri)

#     unless response.is_a?(Net::HTTPSuccess)
#       Rails.logger.error("Failed to fetch devices: #{response.code}")
#       return render json: [], status: :internal_server_error
#     end

#     devices = JSON.parse(response.body)
#     vlan_values = []

#     # Step 2: For each device, trigger refresh for the VLAN parameter
#     devices.each do |device|
#       device_id = device["_id"] # dynamic device id from response
# refresh_uri = URI("#{genieacs_host}/devices/#{device_id}/tasks?connection_request")

#       refresh_req = Net::HTTP::Post.new(refresh_uri, 'Content-Type' => 'application/json')
#       refresh_req.body = {
#         name: "refreshObject",
#           objectName: ""   # Empty means refresh all parameters

#       }.to_json

#       Net::HTTP.start(refresh_uri.hostname, refresh_uri.port) do |http|
#         http.request(refresh_req)
#       end
#     end

#     # Step 3: Give CPEs a moment to respond (basic approach)
#     sleep 1

#     # Step 4: Fetch devices again to get latest values
#     response = Net::HTTP.get_response(devices_uri)
#     if response.is_a?(Net::HTTPSuccess)
#       devices = JSON.parse(response.body)

#       vlan_values = devices.map do |device|
#         device.dig("InternetGatewayDevice", "WANDevice", "1", "WANConnectionDevice", "1", "WANIPConnection", "1", "X_HW_VLAN", "_value")
#       end

#       render json: vlan_values
#     else
#       Rails.logger.error("Failed to fetch updated devices: #{response.code}")
#       render json: [], status: :internal_server_error
#     end

#   rescue => e
#     Rails.logger.error("Error querying GenieACS: #{e.message}")
#     render json: [], status: :internal_server_error
#   end
# end





end
