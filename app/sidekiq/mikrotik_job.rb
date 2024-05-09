class MikrotikJob
  include Sidekiq::Job

require 'net/http'
require 'uri'
require 'json'







  def perform(*args)
    id = '*2'
    # Define the endpoint URL of the MikroTik REST API
    url = URI("http://192.168.88.1/rest/radius")

    username = 'user1'
    password = ''

    # Create a new HTTP request with basic authentication
    request = Net::HTTP::Get.new(url)
    request.basic_auth(username, password)

    # Make an HTTP request to fetch system resources information
    response = Net::HTTP.start(url.host, url.port) do |http|
      http.request(request)
    end

    # Check if the response is successful
    if response.is_a?(Net::HTTPSuccess)
      # Parse the JSON response
      data = JSON.parse(response.body)

      # Print the system resources information
     puts data
      # Add more attributes as needed
    else
      puts "Failed to fetch system resources: #{response.code} - #{response.message}"
    end
  end
end
