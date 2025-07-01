class AcsTestingController < ApplicationController
 def index
    uri = URI("http://102.221.35.92:7347/devices?_limit=10") # Update host/port if needed

    begin
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        @devices = JSON.parse(response.body)
        render json: @devices
      else
        @devices = []
        Rails.logger.error("Failed to fetch devices from GenieACS: #{response.code}")
        render json: @devices, status: :internal_server_error
      end
    rescue => e
      @devices = []
      Rails.logger.error("Error querying GenieACS: #{e.message}")
      render json: @devices, status: :internal_server_error
    end
  end

    
end
