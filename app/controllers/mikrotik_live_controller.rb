

class MikrotikLiveController < ApplicationController


def mikrotik

    # begin
    # url = 'ws://google.com'
    # username = 'admin'
    # password = 'telecomhacker@$'
      
    # ws = WebSocket::Client::Simple.connect('ws://192.168.88.1')

    #   ws.on :open do
    #     ws.send('admin","password')

    #     puts "WebSocket connection opened successfully."
    #     # If no password is set, you can provide an empty string for it
    #   end

    #   ws.on :message do |msg|
    #     puts "Received message: #{msg.data}"
    #   end

    #   ws.on :close do |e|
    #     puts "WebSocket connection closed: #{e}"
    #   end

    #   loop do
    #     sleep 1
    #   end
    # rescue StandardError => e
    #   puts "Error connecting to WebSocket server: #{e.message}"
  
  


#     beginconnection = MTik::Connection.new(
#       host: '192.168.100.14',
#       user: 'user1', 
#       password: '',
#       port: 8728

#     )
#     # beginconnection.xmit('/ip/address') do |response|
#     #   puts response                                          
#     # end
#     beginconnection.xmit("/ip/address/print")
  
# rescue StandardError => e
#   puts "Error communicating with MikroTik device: #{e.message}"

# beginconnection.close()

require 'net/http'
require 'uri'
require 'json'
# Define the endpoint URL of the MikroTik REST API
# url = 'http://192.168.88.1/rest/ip/dhcp-server/network',

 



  
# response = RestClient.post( url:'http://192.168.88.1/rest/beep',

# user:'user1',
# password: '',
# length: 5

# )



require 'net/http'
require 'uri'
require 'json'

uri = URI('http://192.168.88.1/rest/ip/dhcp-server')
request = Net::HTTP::Get.new(uri)
request.basic_auth 'user1', ''
# request.body = { ".proplist": [""] }.to_json

request['Content-Type'] = 'application/json'

  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  if response.is_a?(Net::HTTPSuccess)
    data = JSON.parse(response.body)
    puts data
  else
    puts "Failed to fetch system resources: #{response.code} - #{response.message}"
  end

  # Add a delay between requests (e.g., 1 second)
end
end





