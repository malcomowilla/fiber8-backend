class HotspotTrialController < ApplicationController


  def create

    router_name = params[:router_name]
        
    nas_router = NasRouter.find_by(name: router_name)
  if nas_router
    router_ip_address = nas_router.ip_address
      router_password = nas_router.password
     router_username = nas_router.username
  
  else
  
    puts 'router not found'
  end
    uri = URI("http://#{router_ip_address}/rest/ip/hotspot/host")
    request = Net::HTTP::Get.new(uri)
    request.basic_auth router_username, router_password
    
    
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
      if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)

     data.each do |host|
        puts "MAC Address: #{host['mac-address']}, IP Address: #{host['address']}"
        host_ip = host['address']
       #  client_mac_address = ClientMacAdresses.create(macadress: host['mac-address'])
       #  client_mac_address.update(macadress: host['mac-address'])
 
              
      
    

      #  router_ip = '192.168.80.1'
      #  router_user = 'admin'
      #  router_password = ''
       
       # User details
       user_ip = "#{host_ip}"
      #  username = 'admin2'
       
       # Command to add user to Hotspot active list
       command = "/ip hotspot active login user=admin ip=#{user_ip}"
       
       begin
       Net::SSH.start(router_ip_address, router_username, password: router_password) do |ssh|
       output = ssh.exec!(command)
       puts "Command executed successfully: #{output}"
       end
       rescue StandardError => e
       puts "An error occurred: #{e.message}"
       end            
     end

  
       
      
  puts "mikrotik hosts#{data}"
  
    else
      puts "Failed to fetch limitation: #{response.code} - #{response.message}"
    end
end

end