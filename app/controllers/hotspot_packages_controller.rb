class HotspotPackagesController < ApplicationController
  # before_action :set_hotspot_package, only: %i[ show edit update destroy ]

  # GET /hotspot_packages or /hotspot_packages.json

  load_and_authorize_resource :except => [:allow_get_hotspot_packages]


  set_current_tenant_through_filter

  before_action :set_tenant
  # /ip/hotspot/host?as-string=any&as-string-value=any&number=any&value-name=any
   

  def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    @current_account =ActsAsTenant.current_tenant 
    EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end

  
  def authenticate_hotspot_package


    uri = URI("http://192.168.80.1/rest/ip/hotspot/host")
    request = Net::HTTP::Get.new(uri)
    request.basic_auth 'admin', ''
    
    
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
       #  return  host['address']
       request_body1 = {

       "name": "admin2",
      
       }
       
       uri = URI("http://192.168.80.1/rest/ip/hotspot/user/add")
       request = Net::HTTP::Post.new(uri)
       
       request.basic_auth 'admin', ''
       request.body = request_body1.to_json
       
       request['Content-Type'] = 'application/json'
       
       response = Net::HTTP.start(uri.hostname, uri.port) do |http|
         http.request(request)
       end
       
       if response.is_a?(Net::HTTPSuccess)
         data = JSON.parse(response.body)
         puts "user aded #{data}"


# Router credentials
router_ip = '192.168.80.1'
router_user = 'admin'
router_password = ''

# User details
user_ip = "#{host_ip}"
username = 'admin2'

# Command to add user to Hotspot active list
command = "/ip hotspot active login user=#{username} ip=#{user_ip}"

begin
Net::SSH.start(router_ip, router_user, password: router_password) do |ssh|
output = ssh.exec!(command)
puts "Command executed successfully: #{output}"
end
rescue StandardError => e
puts "An error occurred: #{e.message}"
end            
       
       else
         puts "Failed to add user: #{response.code} - #{response.message}"
       end
       #  
     end

  
       
      
  puts "mikrotik hosts#{data}"
  
    else
      puts "Failed to fetch limitation: #{response.code} - #{response.message}"
    end
  end




  def hotspot_login


    nas_router = NasRouter.find_by(name: router_name)
    if nas_router
      router_ip_address = nas_router.ip_address
        router_password = nas_router.password
       router_username = nas_router.username
    
    else
    
      puts 'router not found'
    end
    uri = URI("http://192.168.80.1/rest/ip/hotspot/host")
    request = Net::HTTP::Get.new(uri)
    request.basic_auth 'admin', ''
    
    
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
       #  return  host['address']
       request_body1 = {

       "name": "admin2",
      
       }
       
       uri = URI("http://192.168.80.1/rest/ip/hotspot/user/add")
       request = Net::HTTP::Post.new(uri)
       
       request.basic_auth 'admin', ''
       request.body = request_body1.to_json
       
       request['Content-Type'] = 'application/json'
       
       response = Net::HTTP.start(uri.hostname, uri.port) do |http|
         http.request(request)
       end
       
       if response.is_a?(Net::HTTPSuccess)
         data = JSON.parse(response.body)
         puts "user aded #{data}"


# Router credentials
router_ip = '192.168.80.1'
router_user = 'admin'
router_password = ''

# User details
user_mac = 'C6:3D:15:54:0F:2E'
user_ip = "#{host_ip}"
username = 'admin2'

# Command to add user to Hotspot active list
command = "/ip hotspot active login user=#{username} ip=#{user_ip}"

begin
Net::SSH.start(router_ip, router_user, password: router_password) do |ssh|
output = ssh.exec!(command)
puts "Command executed successfully: #{output}"
end
rescue StandardError => e
puts "An error occurred: #{e.message}"
end            
       
       else
         puts "Failed to add user: #{response.code} - #{response.message}"
       end
       #  
     end

  
       
      
  puts "mikrotik hosts#{data}"
  
    else
      puts "Failed to fetch limitation: #{response.code} - #{response.message}"
    end
  end






  
  def index
    Rails.logger.info "Router IP: #{params.inspect}"

    @hotspot_packages = HotspotPackage.all
    render json: @hotspot_packages

  end


  def allow_get_hotspot_packages
    Rails.logger.info "Router IP: #{params.inspect}"

    @hotspot_packages = HotspotPackage.all
    render json: @hotspot_packages
  end
  
  # POS T /hotspot_packages or /hotspot_packages.json
  def create


    host = request.headers['X-Subdomain'] 


if host === 'demo'
  


     
  if HotspotPackage.exists?(name: params[:name])
    render json: { error: "ip pool already exists" }, status: :unprocessable_entity
    return
    
  end
  

  
  if params[:name].blank?
    render json: { error: "package name is required" }, status: :unprocessable_entity
    return
  end
  
  # if params[:download_limit].blank?
  #   render json: { error: "download limit is required" }, status: :unprocessable_entity
  #   return
  # end
  
  # if params[:upload_limit].blank?
  #   render json: { error: "upload limit is required" }, status: :unprocessable_entity
  #   return
  # end
  
  if params[:price].blank?
    render json: { error: "price is required" }, status: :unprocessable_entity
    return
  end
  @hotspot_package = HotspotPackage.new(hotspot_package_params)
  # use_radius = ActsAsTenant.current_tenant.&router_setting&.use_radius



    if @hotspot_package.save
    
           
        render json: @hotspot_package, status: :created
    else
   render json: @hotspot_package.errors, status: :unprocessable_entity
    end



  
  
else
       
  if HotspotPackage.exists?(name: params[:name])
    render json: { error: "ip pool already exists" }, status: :unprocessable_entity
    return
    
  end
  

  
  if params[:name].blank?
    render json: { error: "package name is required" }, status: :unprocessable_entity
    return
  end
  
  # if params[:download_limit].blank?
  #   render json: { error: "download limit is required" }, status: :unprocessable_entity
  #   return
  # end
  
  # if params[:upload_limit].blank?
  #   render json: { error: "upload limit is required" }, status: :unprocessable_entity
  #   return
  # end
  
  if params[:price].blank?
    render json: { error: "price is required" }, status: :unprocessable_entity
    return
  end
  @hotspot_package = HotspotPackage.new(hotspot_package_params)
  use_radius = ActsAsTenant.current_tenant.router_setting.use_radius

  if !use_radius


    if @hotspot_package.save
      # profile_id= fetch_profile_id_from_mikrotik
      # limitation_id = fetch_limitation_id_from_mikrotik
      # profile_limitation_id =  fetch_profile_limitation_id
      user_profile_id = fetch_user_profile_id_from_mikrotik  
      
      # if profile_id && limitation_id && profile_limitation_id && user_profile_id

      if user_profile_id
        # @hotspot_package.update(limitation_id: limitation_id,
        #  profile_limitation_id: profile_limitation_id, profile_id: profile_id,user_profile_id: user_profile_id)

        @hotspot_package.update(user_profile_id: user_profile_id)
        render json: @hotspot_package, status: :created
      else
        render json: { error: 'Failed to obtain the  ids from mikrotik' }, status: :unprocessable_entity
      end
        
        # render json: @hotspot_package, status: :created
    else
   render json: @hotspot_package.errors, status: :unprocessable_entity
    end

  else

  
    if @hotspot_package.save
      profile_id= fetch_profile_id_from_mikrotik
      limitation_id = fetch_limitation_id_from_mikrotik
      profile_limitation_id =  fetch_profile_limitation_id
      
      if profile_id && limitation_id && profile_limitation_id 

        @hotspot_package.update(limitation_id: limitation_id,
         profile_limitation_id: profile_limitation_id, profile_id: profile_id)

        render json: @hotspot_package, status: :created
      else
        render json: { error: 'Failed to obtain the  ids from mikrotik' }, status: :unprocessable_entity
      end
        
        # render json: @hotspot_package, status: :created
    else
   render json: @hotspot_package.errors, status: :unprocessable_entity
    end

  end
end

 
  end







  # PATCH/PUT /hotspot_packages/1 or /hotspot_packages/1.json
  def update
   
      
      host = request.headers['X-Subdomain'] 

      
      if host == 'demo'
        @hotspot_package = HotspotPackage.find(params[:id])
        

        if  @hotspot_package
          @hotspot_package.update(hotspot_package_params)
        render json: @hotspot_package
        else
          
          render json: { error: 'Hotspot package not found' }, status: :not_found
        end
      else


      use_radius = ActsAsTenant.current_tenant.router_setting.use_radius
      @hotspot_package = set_hotspot_package


if  use_radius == true

      if @hotspot_package
        router_name = params[:router_name]
      nas_router = NasRouter.find_by(name: router_name)
      if nas_router
        router_ip_address = nas_router.ip_address
        router_password = nas_router.password
        router_username = nas_router.username
      else
        puts 'router not found'
      end





      profile_id =  @hotspot_package.profile_id
      limitation_id =  @hotspot_package.limitation_id
      # user_profile_id =  @hotspot_package.user_profile_id

      if profile_id.present? && limitation_id.present?
      # if user_profile_id.present?
        
        download_limit = params[:download_limit]
        upload_limit = params[:upload_limit]
    
      upload_burst_limit = params[:upload_burst_limit]
      download_burst_limit = params[:download_burst_limit]
          validity = params[:validity]
              
    price =  params[:price]
  
          validity_period_units = params[:validity_period_units]
      name = params[:name]
  
      
    validity_period  =   if validity_period_units == 'days'
      "#{validity}d 00:00:00"
    
      elsif validity_period_units == 'hours'
        "#{validity}:00:00"

         elsif validity_period_units == 'minutes'
      "00:#{validity}:00"
      
      end




        req_body={
          "name" => name,

          :price => price,
          :validity => validity_period

        }


          
  

                req_body2 = {
      
                # "download-limit" => download_limit,
                # "upload-limit" => upload_limit,
            "name" => name,
            # "rate-limit-rx" => "#{upload_limit}M",
            # "rate-limit-tx" => "#{download_limit}M",
            # "rate-limit-burst-rx" => "#{upload_burst_limit}M",
            # "rate-limit-burst-tx" => "#{download_burst_limit}M",
            # "uptime-limit" => validity_period
              }

              req_body2["rate-limit-rx"] = "#{upload_limit}M" if upload_limit.present?
              req_body2["rate-limit-tx"] = "#{download_limit}M" if download_limit.present?
              req_body2["rate-limit-burst-rx"] = "#{upload_burst_limit}M" if upload_burst_limit.present?
              req_body2["rate-limit-burst-tx"] = "#{download_burst_limit}M" if download_burst_limit.present?
              req_body2["uptime-limit"] = "#{validity_period}" if validity_period.present?
                  
               




             

                # /ip/hotspot/user/profile/add
                uri = URI("http://#{router_ip_address}/rest/user-manager/profile/#{profile_id}") 
                uri2 = URI("http://#{router_ip_address}/rest/user-manager/limitation/#{limitation_id}") 


                # uri3 = URI("http://#{router_ip_address}/rest/ip/hotspot/user/profile/#{user_profile_id}")


                req = Net::HTTP::Patch.new(uri)
                req2 = Net::HTTP::Patch.new(uri2)
                  #  req3 = Net::HTTP::Patch.new(uri3)

                    req.basic_auth router_username, router_password
                    req2.basic_auth router_username, router_password
                  #  req3.basic_auth router_username, router_password

                    req['Content-Type'] = 'application/json'
                    req2['Content-Type'] = 'application/json'
                    # req3['Content-Type'] = 'application/json'

          req.body = req_body.to_json
          req2.body = req_body2.to_json
          # req3.body = req_body3.to_json

          
          response = Net::HTTP.start(uri.hostname, uri.port){|http| http.request(req)}
          response2 = Net::HTTP.start(uri2.hostname, uri2.port){|http| http.request(req2)} 

          if response.is_a?(Net::HTTPSuccess) && response2.is_a?(Net::HTTPSuccess)

          

    request_body3 = {
      #    "from-time": format_for_mikrotik(params[:valid_from]),
      # "till-time": format_for_mikrotik(params[:valid_until]),
      # "weekdays": 'monday',
        profile:  name,
        limitation: name,
        # weekdays: format_weekdays(params[:weekdays]) 
        }
        request_body3["from-time"] = format_for_mikrotik(params[:valid_from]) if params[:valid_from].present?
    request_body3["till-time"] = format_for_mikrotik(params[:valid_until]) if params[:valid_until].present?
    request_body3["weekdays"] = format_weekdays(params[:weekdays]) if params[:weekdays].present? 
        
        
        uri = URI("http://#{router_ip_address}/rest/user-manager/profile-limitation/#{@hotspot_package.profile_limitation_id}")
        request3 = Net::HTTP::Patch.new(uri)
        request3.basic_auth router_username, router_password
        request3.body = request_body3.to_json
        
        request3['Content-Type'] = 'application/json'
        
        response3 = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(request3)
        end
        
        if response3.is_a?(Net::HTTPSuccess)
          @hotspot_package.update(hotspot_package_params)
          render json: @hotspot_package
          # data = JSON.parse(response.body)
          # return data['ret']
        else
          puts "Failed to update profile limitation: #{response3.code} - #{response3.message}"
        end
          
        else
          puts "Failed to update profile:#{response.code} - #{response.message}"
          puts "Failed to update limitation:#{response2.code} - #{response2.message}"

          render json: { error: "Failed to update package" }, status: :unprocessable_entity

        end
      
        
      else
      
        render json: { error: "limitation ID, or profile ID not found in the package" }, status: :unprocessable_entity

      end
      else
        render json: { error: 'Unprocesable entity' }, status: :unprocessable_entity
      end

    else


      if @hotspot_package
        router_name = params[:router_name]
      nas_router = NasRouter.find_by(name: router_name)
      if nas_router
        router_ip_address = nas_router.ip_address
        router_password = nas_router.password
        router_username = nas_router.username
      else
        puts 'router not found'
      end





      profile_id =  @hotspot_package.profile_id
      limitation_id =  @hotspot_package.limitation_id
      user_profile_id =  @hotspot_package.user_profile_id

      # if profile_id.present? && limitation_id.present?
      if user_profile_id.present?
        
        download_limit = params[:download_limit]
        upload_limit = params[:upload_limit]
    
      upload_burst_limit = params[:upload_burst_limit]
      download_burst_limit = params[:download_burst_limit]
          validity = params[:validity]
              
    price =  params[:price]
  
          validity_period_units = params[:validity_period_units]
      name = params[:name]
  
      
    validity_period  =   if validity_period_units == 'days'
      "#{validity}d 00:00:00"
    
      elsif validity_period_units == 'hours'
        "#{validity}:00:00"

         elsif validity_period_units == 'minutes'
      "00:#{validity}:00"
      
      end




          
    
                req_body2 = {
                  
                  # "download-limit" => download_limit,
                  # "upload-limit" => upload_limit,
              "name" => name,
              # "rate-limit-rx" => "#{upload_limit}M",
              # "rate-limit-tx" => "#{download_limit}M",
              # "rate-limit-burst-rx" => "#{upload_burst_limit}M",
              # "rate-limit-burst-tx" => "#{download_burst_limit}M",
              "uptime-limit" => validity_period
                }




              req_body4 = {
                # "address-list": "any",
                # "address-pool": "any",
              
                
                "name": "#{name}",
                "rate-limit": "#{upload_limit}M/#{download_limit}M",
                "session-timeout": "#{validity_period}",
                # "shared-users": "any",
               
              
            
            }

                # /ip/hotspot/user/profile/add
                # uri = URI("http://#{router_ip_address}/rest/user-manager/profile/#{profile_id}") 
                # uri2 = URI("http://#{router_ip_address}/rest/user-manager/limitation/#{limitation_id}") 


                uri3 = URI("http://#{router_ip_address}/rest/ip/hotspot/user/profile/#{user_profile_id}")


                # req = Net::HTTP::Patch.new(uri)
                # req2 = Net::HTTP::Patch.new(uri2)
                   req3 = Net::HTTP::Patch.new(uri3)

                    # req.basic_auth router_username, router_password
                    # req2.basic_auth router_username, router_password
                   req3.basic_auth router_username, router_password

                    # req['Content-Type'] = 'application/json'
                    # req2['Content-Type'] = 'application/json'
                    req3['Content-Type'] = 'application/json'

          # req.body = req_body.to_json
          # req2.body = req_body2.to_json
          req3.body = req_body4.to_json

          # req2.body =   if params[:download_limit].present? && params[:upload_limit].present?
                 

          # response = Net::HTTP.start(uri.hostname, uri.port){|http| http.request(req)}
          # response2 = Net::HTTP.start(uri2.hostname, uri2.port){|http| http.request(req2)} 
          response3 = Net::HTTP.start(uri3.hostname, uri3.port){|http| http.request(req3)}

          if response.is_a?(Net::HTTPSuccess) && response2.is_a?(Net::HTTPSuccess) && response3.is_a?(Net::HTTPSuccess)

        # if response3.is_a?(Net::HTTPSuccess)
          @hotspot_package.update(hotspot_package_params)
          render json: @hotspot_package
        else
          puts "Failed to update profile  : #{response.code} - #{response.message}"
          puts "Failed to update limitation : #{response2.code} - #{response2.message}"

          render json: { error: "Failed to update package" }, status: :unprocessable_entity

        end
      
        
      else
      
        render json: { error: "user profile id not found in the package" }, status: :unprocessable_entity

      end
      else
        render json: { error: 'Unprocesable entity' }, status: :unprocessable_entity
      end

    
    end

        
      end
      
    
  end





  # DELETE /hotspot_packages/1 or /hotspot_packages/1.json
  def destroy


    host = request.headers['X-Subdomain'] 
    if host === 'demo'
      @hotspot_package = set_hotspot_package
      @hotspot_package.destroy!
      render json: { message: "Package deleted successfully" }
      
    else

      use_radius = ActsAsTenant.current_tenant.router_setting.use_radius
    if use_radius == false
    #    head :no_content 
    @hotspot_package = set_hotspot_package
       if @hotspot_package
        router_name = params[:router_name]
        nas_router = NasRouter.find_by(name: router_name)
        if nas_router
          router_ip_address = nas_router.ip_address
          router_password = nas_router.password
          router_username = nas_router.username
        else
          puts 'router not found'
        end
    
       user_profile_id = @hotspot_package.user_profile_id

        if user_profile_id.present?
          uri = URI("http://#{router_ip_address}/rest/user-manager/profile/#{profile_id}")
          uri2 = URI("http://#{router_ip_address}/rest/user-manager/limitation/#{limitation_id}")
          
    
          request = Net::HTTP::Delete.new(uri)
          request2 = Net::HTTP::Delete.new(uri2)
    
          request.basic_auth router_username, router_password
          request2.basic_auth router_username, router_password
    
          response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
          response2 = Net::HTTP.start(uri2.hostname, uri2.port) { |http| http.request(request2) }
    
          if  response2.is_a?(Net::HTTPSuccess) && response.is_a?(Net::HTTPSuccess) && response4.is_a?(Net::HTTPSuccess)
            @hotspot_package.destroy!
            head :no_content
          else
            render json: { error: "Failed to delete profile, limitation, and profile limitation from Mikrotik" }, status: :unprocessable_entity
          end
        else
          render json: { error: "Mikrotik ID, limitation ID, or profile limitation ID not found in the package" }, status: :unprocessable_entity
        end


      else
        render json: { error: "Package not found" }, status: :not_found
      end


    elsif use_radius == true


 #    head :no_content 
 @hotspot_package = set_hotspot_package
 if @hotspot_package
  router_name = params[:router_name]
  nas_router = NasRouter.find_by(name: router_name)
  if nas_router
    router_ip_address = nas_router.ip_address
    router_password = nas_router.password
    router_username = nas_router.username
  else
    puts 'router not found'
  end


  

  profile_limitation_id = @hotspot_package.profile_limitation_id
  limitation_id = @hotspot_package.limitation_id
  profile_id = @hotspot_package.profile_id

  if profile_id.present?  && limitation_id.present? && profile_limitation_id.present? 

    uri = URI("http://#{router_ip_address}/rest/user-manager/profile/#{profile_id}")
    uri2 = URI("http://#{router_ip_address}/rest/user-manager/limitation/#{limitation_id}")
    

    request = Net::HTTP::Delete.new(uri)
    request2 = Net::HTTP::Delete.new(uri2)

    request.basic_auth router_username, router_password
    request2.basic_auth router_username, router_password

    response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
    response2 = Net::HTTP.start(uri2.hostname, uri2.port) { |http| http.request(request2) }

    if  response2.is_a?(Net::HTTPSuccess) && response.is_a?(Net::HTTPSuccess) 
      @hotspot_package.destroy
      head :no_content
    else
      render json: { error: "Failed to delete profile, limitation, and profile limitation from Mikrotik" }, status: :unprocessable_entity
    end
  else
    render json: { error: "Mikrotik ID, limitation ID, or profile limitation ID not found in the package" }, status: :unprocessable_entity
  end


  profile_limitation_id = @hotspot_package.profile_limitation_id

  uri3 = URI("http://#{router_ip_address}/rest/user-manager/profile-limitation/#{profile_limitation_id}")
  request3 = Net::HTTP::Delete.new(uri3)

  request3.basic_auth router_username, router_password

  response3 = Net::HTTP.start(uri3.hostname, uri3.port) { |http| http.request(request3) }

  if response3.is_a?(Net::HTTPSuccess)
    puts 'profile limitation deleted'
  else
    "failed  to delete #{response4.code} - #{response4.message}"
  end
else
  render json: { error: "Package not found" }, status: :not_found
end



end 
    end

end






  private



#   def fetch_profile_limitation_id
  

#     # router_name = session[:router_name]
#     router_name = params[:router_name]
  
#           nas_router = NasRouter.find_by(name: router_name)
#         if nas_router
#           router_ip_address = nas_router.ip_address
#             router_password = nas_router.password
#            router_username = nas_router.username
        
#         else
        
#           puts 'router not found'
#         end
  
#         name = params[:name]
  

# #         {
# #   "comment": "any",
# #   "copy-from": "any",
# #   "from-time": "any",
# #   "limitation": "any",
# #   "profile": "any",
# #   "till-time": "any",
# #   "weekdays": "any",
# #   ".proplist": "any",
# #   ".query": "array"
# # }

# Rails.logger.info("valid_from: #{format_for_mikrotik(params[:valid_from])}")
# Rails.logger.info("valid_until: #{format_for_mikrotik(params[:valid_until])}")
# Rails.logger.info("weekdays: #{format_weekdays(params[:weekdays])}")
#     user1 = router_username
#     password = router_password


#     request_body3 = {
#   #    "from-time": format_for_mikrotik(params[:valid_from]),
#   # "till-time": format_for_mikrotik(params[:valid_until]),
#   # "weekdays": 'monday',
#     profile:  name,
#     limitation: name,
#     # weekdays: format_weekdays(params[:weekdays]) 
#     }
#     request_body3["from-time"] = format_for_mikrotik(params[:valid_from]) if params[:valid_from].present?
# request_body3["till-time"] = format_for_mikrotik(params[:valid_until]) if params[:valid_until].present?
# request_body3["weekdays"] = format_weekdays(params[:weekdays]) if params[:weekdays].present? 
    
    
#     uri = URI("http://#{router_ip_address}/rest/user-manager/profile-limitation/add")
#     request = Net::HTTP::Post.new(uri)
#     request.basic_auth user1, password
#     request.body = request_body3.to_json
    
#     request['Content-Type'] = 'application/json'
    
#     response = Net::HTTP.start(uri.hostname, uri.port) do |http|
#       http.request(request)
#     end
    
#     if response.is_a?(Net::HTTPSuccess)
#       data = JSON.parse(response.body)
#       return data['ret']
#     else
#       puts "Failed to post profile limitation: #{response.code} - #{response.message}"
#     end
        
    
  
#   end









def fetch_profile_limitation_id
  router_name = params[:router_name]
  nas_router = NasRouter.find_by(name: router_name)

  unless nas_router
    Rails.logger.error "Router not found: #{router_name}"
    return nil
  end

  name = params[:name]
  valid_from = format_for_mikrotik(params[:valid_from])
  valid_until = format_for_mikrotik(params[:valid_until])
  weekdays = format_weekdays(params[:weekdays])

  # Ensure attributes are updated or created
  attributes = [
    { radius_attribute: 'Session-Timeout', value: valid_until },
    { radius_attribute: 'Start-Time', value: valid_from },
    { radius_attribute: 'Weekdays', value: weekdays }
    
  ]

  attributes.each do |attr|
    next if attr[:value].blank? # Skip empty values

    existing_entry = RadGroupReply.find_by(groupname: name, radius_attribute: attr[:radius_attribute])

    if existing_entry
      existing_entry.update(value: attr[:value])
    else
      RadGroupReply.create(groupname: name, radius_attribute: attr[:radius_attribute], op: ':=', value: attr[:value])
    end
  end

  Rails.logger.info "Profile limitation updated in FreeRADIUS"
end



  def format_weekdays(weekdays)
    return '' unless weekdays.present?
  
    weekdays.map(&:downcase).join(',') # Convert to lowercase and join with commas
  end

  def format_for_mikrotik(datetime)
    return '' unless datetime.present?
  
    # Parse and convert to local time
    parsed_time = Time.parse(datetime).in_time_zone("Nairobi") rescue nil
    return '' unless parsed_time
  
    # Format directly for MikroTik (HH:MM:SS)
    parsed_time.strftime('%H:%M:%S')
  end
  


  #  def fetch_profile_id_from_mikrotik
        
  #       # router_name = session[:router_name]
  # router_name = params[:router_name]
  #       nas_router = NasRouter.find_by(name: router_name)
  #     if nas_router
  #       router_ip_address = nas_router.ip_address
  #         router_password = nas_router.password
  #        router_username = nas_router.username
      
  #     else
      
  #       puts 'router not found'
  #     end
    
  
 
  #   name = params[:name]
     
  #     validity = params[:validity]
  #     validity_period_units = params[:validity_period_units]
  #     price =  params[:price]
    
  
    
  #  validity_period =   if validity_period_units == 'days'
  #   "#{validity}d 00:00:00"
  
  #   elsif validity_period_units == 'hours'
  #      "#{validity}:00:00"


  #   elsif validity_period_units == 'minutes'
  #     "00:#{validity}:00"
    
  #   end
  
    
  
    
  #   request_body1={
  #     name: name,
  #   validity: validity_period ,
  #   price: price
  #   }
    
  
  #   # request_body1["price"] = price if price.present?
  #   # request_body1["validity"] = validity_period if validity_period.present?
  #   Rails.logger.info "request_body1: #{request_body1}"

  
  # uri = URI("http://#{router_ip_address}/rest/user-manager/profile/add")
  # request = Net::HTTP::Post.new(uri)
  
  # request.basic_auth router_username, router_password
  # request.body = request_body1.to_json
  
  # request['Content-Type'] = 'application/json'
  
  #   response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  #     http.request(request)
  #   end
  
  #   if response.is_a?(Net::HTTPSuccess)
  #     data = JSON.parse(response.body)
  #     return data['ret']
     

  #   else
  #     puts "Failed to profile: #{response.code} - #{response.message}"
  #   end
  

  #       end

  def fetch_profile_id_from_mikrotik
    name = params[:name]
    validity = params[:validity]
    validity_units = params[:validity_period_units]
    price = params[:price]
  
    # Convert validity to FreeRADIUS time format
   
   validity_period =   if validity_units == 'days'
    (Time.now + (validity.to_i * 86400)).strftime("%Y-%m-%d %H:%M:%S")  # Convert days to seconds
  
    elsif validity_units == 'hours'
      (Time.now + (validity.to_i * 3600)).strftime("%Y-%m-%d %H:%M:%S")   # Convert hours to seconds


    elsif validity_units == 'minutes'
      (Time.now + (validity.to_i * 60)).strftime("%Y-%m-%d %H:%M:%S")    # Convert minutes to seconds
    
    end
  
    # Insert into `radgroupcheck` for profile conditions
#     RadGroupCheck.create(groupname: name, :"radius_attribute" => 'Auth-Type', op: ':=', value: 'Accept')
# RadGroupCheck.create(groupname: name, :"radius_attribute" => 'Session-Timeout', op: ':=', value: validity_period) if validity_period

sql = <<-SQL
  INSERT INTO radgroupcheck (groupname, radius_attribute, op, value)
  VALUES 
    ('#{name}', 'Auth-Type', ':=', 'Accept')
    #{validity_period ? ", ('#{name}', 'Expiration', ':=', '#{validity_period}')" : ""}
SQL

# Execute the SQL
ActiveRecord::Base.connection.execute(sql)


    return name  # Returning profile name as reference
  end
  

    #     def fetch_user_profile_id_from_mikrotik
    #       # /ip/hotspot/user/profile/add
    #       # router_name = session[:router_name]
    #       router_name = params[:router_name]
    #       validity = params[:validity]
    #       nas_router = NasRouter.find_by(name: router_name)
    #     if nas_router
    #       router_ip_address = nas_router.ip_address
    #         router_password = nas_router.password
    #        router_username = nas_router.username
        
    #     else
        
    #       puts 'router not found'
    #     end
    #     validity_period_units = params[:validity_period_units]

    #     validity_period =   if validity_period_units == 'days'
    #       "#{validity}d 00:00:00"
        
    #       elsif validity_period_units == 'hours'
    #          "#{validity}:00:00"
    #           elsif validity_period_units == 'minutes'
    # "00:#{validity}:00"
          
    #       end


    #       download_limit = params[:download_limit] 
    #       upload_limit = params[:upload_limit] 



          
    #     name = params[:name]
    #     request_body2 = {
    #       # "address-list": "any",
    #       # "address-pool": "any",
        
          
    #       "name": "#{name}",
         
    #       "rate-limit": "#{upload_limit}M/#{download_limit}M",
    #       "session-timeout": "#{validity_period}",
    #       # "shared-users": "any",
         
        
      
    #   }


    #   request_body = {
    #     # "address-list": "any",
    #     # "address-pool": "any",
      
        
    #     "name": "#{name}",
       
    #     "session-timeout": "#{validity_period}",
    #     # "shared-users": "any",
       
      
    
    # }
    
    #   # request_body2.to_json
    # uri = URI("http://#{router_ip_address}/rest/ip/hotspot/user/profile/add")
    # request = Net::HTTP::Post.new(uri)
    
    # request.basic_auth router_username, router_password
    # request.body =   if params[:download_limit].present? && params[:upload_limit].present?
    #   request_body2.to_json

   

    #  else
    #    request_body.to_json
    #  end
    

    # request['Content-Type'] = 'application/json'
    
    # response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    #   http.request(request)
    # end
    
    # if response.is_a?(Net::HTTPSuccess)
    #   data = JSON.parse(response.body)
    #         return data['ret']
  
    # else
    #   puts "Failed to fetch user profile id : #{response.code} - #{response.message}"
    # end


    #     end










    def fetch_user_profile_id_from_mikrotik
      name = params[:name]
      validity = params[:validity]
      validity_units = params[:validity_period_units]
      upload_limit = params[:upload_limit]
      download_limit = params[:download_limit]
    
      validity_period = case validity_units
                        when 'days' then "#{validity * 86400}" # Convert to seconds
                        when 'hours' then "#{validity * 3600}"
                        when 'minutes' then "#{validity * 60}"
                        end
    
      # Apply to `radreply`
      # RadReply.create(username: name, :"radius_attribute" => 'Session-Timeout', op: ':=', value: validity_period) if validity_period
      # RadReply.create(username: name, :"radius_attribute" => 'Mikrotik-Rate-Limit', op: ':=', value: "#{upload_limit}M/#{download_limit}M") if upload_limit && download_limit
      # ActiveRecord::Base.connection.execute("INSERT INTO radreply (username, radius_attribute, op, value) VALUES ('#{name}', 'Session-Timeout', ':=', '#{validity_period}')")
      # ActiveRecord::Base.connection.execute("INSERT INTO radreply (username, radius_attribute, op, value) VALUES ('#{name}', 'Mikrotik-Rate-Limit', ':=', '#{upload_limit}M/#{download_limit}M')")

      sql_statements = []

      if validity_period
        sql_statements << "INSERT INTO radgroupreply (groupname, radius_attribute, op, value) VALUES ('#{name}', 'Session-Timeout', ':=', '#{validity_period}');"
      end
      
      if upload_limit && download_limit
        sql_statements << "INSERT INTO radgroupreply (groupname, radius_attribute, op, value) VALUES ('#{name}', 'Mikrotik-Rate-Limit', ':=', '#{upload_limit}M/#{download_limit}M');"
      end
      
      if upload_burst_limit && download_burst_limit
        sql_statements << "INSERT INTO radgroupreply (groupname, radius_attribute, op, value) VALUES ('#{name}', 'Mikrotik-Burst-Limit', ':=', '#{upload_burst_limit}M/#{download_burst_limit}M');"
      end
      
      sql_statements.each do |sql|
        ActiveRecord::Base.connection.execute(sql)
      end
      return name  # Returning username as reference
    end
    





#         def fetch_limitation_id_from_mikrotik
  
#           router_name = params[:router_name]
        
#                 nas_router = NasRouter.find_by(name: router_name)
#               if nas_router
#                 router_ip_address = nas_router.ip_address
#                   router_password = nas_router.password
#                  router_username = nas_router.username
              
#               else
              
#                 puts 'router not found'
#               end
            
          
            
            
#            download_limit = params[:download_limit] if params[:download_limit].present?
#               upload_limit = params[:upload_limit] if params[:upload_limit].present?
           
#             upload_burst_limit = params[:upload_burst_limit]
#             download_burst_limit = params[:download_burst_limit]
#                 validity = params[:validity]
#                 validity_period_units = params[:validity_period_units]
#             name = params[:name]
        
            
#            validity_period =   if validity_period_units == 'days'
#             "#{validity}d 00:00:00"
          
#             elsif validity_period_units == 'hours'
#                "#{validity}:00:00"
#                 elsif validity_period_units == 'minutes'
#       "00:#{validity}:00"
            
#             end
          
            
          
#             request_body2 = {
              
#               # "download-limit" => download_limit,
#               # "upload-limit" => upload_limit,
#           "name" => name,
#           # "rate-limit-rx" => "#{upload_limit}M",
#           # "rate-limit-tx" => "#{download_limit}M",
#           # "rate-limit-burst-rx" => "#{upload_burst_limit}M",
#           # "rate-limit-burst-tx" => "#{download_burst_limit}M",
#           # "uptime-limit" => validity_period
#             }

#             request_body2["uptime-limit"] = "#{validity_period}" if validity_period.present?
 
#             request_body2["rate-limit-tx"] = "#{download_limit}M" if download_limit.present?
#             request_body2["rate-limit-rx"] = "#{upload_limit}M" if upload_limit.present?
#             request_body2["rate-limit-burst-tx"] = "#{download_burst_limit}M" if download_burst_limit.present?
#             request_body2["rate-limit-burst-rx"] = "#{upload_burst_limit}M" if upload_burst_limit.present?


# Rails.logger.info "request_body2: #{request_body2}"
          
#           uri = URI("http://#{router_ip_address}/rest/user-manager/limitation/add")
#           request = Net::HTTP::Post.new(uri)
          
#           request.basic_auth router_username, router_password
#           request.body = request_body2.to_json
          
#           request['Content-Type'] = 'application/json'
          
#           response = Net::HTTP.start(uri.hostname, uri.port) do |http|
#             http.request(request)
#           end
          
#           if response.is_a?(Net::HTTPSuccess)
#             data = JSON.parse(response.body)
#                   return data['ret']
        
#           else
#             puts "Failed to post limitation_id : #{response.code} - #{response.message}"
#           end
              
          
#         end



def fetch_limitation_id_from_mikrotik
  name = params[:name]
  validity = params[:validity]
  validity_units = params[:validity_period_units]
  upload_limit = params[:upload_limit]
  download_limit = params[:download_limit]
  upload_burst_limit = params[:upload_burst_limit]
  download_burst_limit = params[:download_burst_limit]

  # Convert validity time
  validity_period = case validity_units
                    when 'days' then "#{validity * 86400}" # Convert to seconds
                    when 'hours' then "#{validity * 3600}"
                    when 'minutes' then "#{validity * 60}"
                    end

  # Insert into `radgroupreply`
  # RadGroupReply.create(groupname: name, :"radius_attribute" => 'Session-Timeout', op: ':=', value: validity_period) if validity_period
  # RadGroupReply.create(groupname: name, :"radius_attribute" => 'Mikrotik-Rate-Limit', op: ':=', value: "#{upload_limit}M/#{download_limit}M") if upload_limit && download_limit
  # RadGroupReply.create(groupname: name, :"radius_attribute" => 'Mikrotik-Burst-Limit', op: ':=', value: "#{upload_burst_limit}M/#{download_burst_limit}M") if upload_burst_limit && download_burst_limit

  sql = <<-SQL
  INSERT INTO radgroupreply (groupname, radius_attribute, op, value)
  VALUES 
    #{validity_period ? "('#{name}', 'Session-Timeout', ':=', '#{validity_period}')" : nil},
    #{upload_limit && download_limit ? "('#{name}', 'Mikrotik-Rate-Limit', ':=', '#{upload_limit}M/#{download_limit}M')" : nil},
    #{upload_burst_limit && download_burst_limit ? "('#{name}', 'Mikrotik-Burst-Limit', ':=', '#{upload_burst_limit}M/#{download_burst_limit}M')" : nil}
SQL

# Remove nil values and execute SQL if there's anything to insert
sql.gsub!(/,\s*nil/, '') # Remove trailing nil values
ActiveRecord::Base.connection.execute(sql) unless sql.include?("nil")
  record[:attribute] = 'Auth-Type'
  return name  # Returning limitation name as reference
end



    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_package
      @hotspot_package = HotspotPackage.find_by(id: params[:id])
    end


    
    # Only allow a list of trusted parameters through.
    def hotspot_package_params
      params.permit(
        :name,
        :price,
        :download_limit,
        :upload_limit,
        :valid_from,
        :valid_until,
          # Correct array syntax
        :tx_rate_limit,
        :rx_rate_limit,
        :validity_period_units,
        :download_burst_limit,
        :upload_burst_limit,
        :validity ,
        weekdays: [],
      )
    end
    
end



