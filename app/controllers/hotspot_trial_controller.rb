class HotspotTrialController < ApplicationController


#   def create

#     router_name = params[:router_name]
        
#     nas_router = NasRouter.find_by(name: router_name)
#   if nas_router
#     router_ip_address = nas_router.ip_address
#       router_password = nas_router.password
#      router_username = nas_router.username
  
#   else
  
#     puts 'router not found'
#   end
#     uri = URI("http://#{router_ip_address}/rest/ip/hotspot/host")
#     request = Net::HTTP::Get.new(uri)
#     request.basic_auth router_username, router_password
    
    
#     response = Net::HTTP.start(uri.hostname, uri.port) do |http|
#       http.request(request)
#     end
    
#       if response.is_a?(Net::HTTPSuccess)
#       data = JSON.parse(response.body)

#      data.each do |host|
#         puts "MAC Address: #{host['mac-address']}, IP Address: #{host['address']}"
#         host_ip = host['address']
#         host_mac = host['mac-address']
#        #  client_mac_address = ClientMacAdresses.create(macadress: host['mac-address'])
#        #  client_mac_address.update(macadress: host['mac-address'])
 
              
      
    

#       #  router_ip = '192.168.80.1'
#        router_user = 'admin'
#       #  router_password = ''
       
#        # User details
#        user_ip = "#{host_ip}"
#       #  username = 'admin2'
       
#        # Command to add user to Hotspot active list
#        command = "/ip hotspot active login user=#{router_user} ip=#{host_ip}"
       
#        begin
#         Net::SSH.start(router_ip_address, router_username, password: router_password, verify_host_key: :never) do |ssh|
#        output = ssh.exec!(command)
#        puts "Command executed successfully: #{output}"
#        end
#        rescue StandardError => e
#        puts "An error occurred: #{e.message}"
#        end            
#      end

  
       
      
#   puts "mikrotik hosts#{data}"
  
#     else

#       render json: {error: "Failed to fetch mikrotik hosts"}, status: 500

#       # puts "Failed to fetch limitation: #{response.code} - #{response.message}"
#     end
# end


require 'net/http'
require 'json'
require 'net/ssh'

def create
  router_name = params[:router_name]

  nas_router = NasRouter.find_by(name: router_name)
  
  unless nas_router
    return render json: { error: 'Router not found' }, status: 404
  end

  router_ip_address = nas_router.ip_address
  router_password = nas_router.password
  router_username = nas_router.username

  uri = URI("http://#{router_ip_address}/rest/ip/hotspot/host")
  request = Net::HTTP::Get.new(uri)
  request.basic_auth router_username, router_password

  response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }

  unless response.is_a?(Net::HTTPSuccess)
    return render json: { error: "Failed to fetch Mikrotik hosts", status: response.code, message: response.message }, status: 500
  end

  data = JSON.parse(response.body)
  failed_hosts = []
  successful_hosts = []

  data.each do |host|
    host_ip = host['address']
    host_mac = host['mac-address']

    command = "/ip hotspot active login user=admin ip=#{host_ip}"
    
    begin
      Net::SSH.start(router_ip_address, router_username, password: router_password, verify_host_key: :never) do |ssh|
        output = ssh.exec!(command)
        successful_hosts << { ip: host_ip, mac: host_mac, response: output }
      end
    rescue StandardError => e
      failed_hosts << { ip: host_ip, mac: host_mac, error: e.message }
    end
  end

  render json: {
    message: 'Mikrotik host data processed successfully',
    successful_hosts: successful_hosts,
    failed_hosts: failed_hosts
  }, status: :ok
end







end