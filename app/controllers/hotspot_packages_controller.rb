class HotspotPackagesController < ApplicationController
  before_action :set_hotspot_package, only: %i[ show edit update destroy ]

  # GET /hotspot_packages or /hotspot_packages.json



  # /ip/hotspot/host?as-string=any&as-string-value=any&number=any&value-name=any
   


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
    @hotspot_packages = HotspotPackage.all
    render json: @hotspot_packages

  end

  
  # POST /hotspot_packages or /hotspot_packages.json
  def create
    @hotspot_package = HotspotPackage.new(hotspot_package_params)

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
    
  end





  # PATCH/PUT /hotspot_packages/1 or /hotspot_packages/1.json
  def update
      # if @hotspot_package.update(hotspot_package_params)
      #   render json: @hotspot_package
      # else
      #    render json: @hotspot_package.errors, status: :unprocessable_entity 
      # end

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





      # profile_id =  @hotspot_package.profile_id
      # limitation_id =  @hotspot_package.limitation_id
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
              "uptime-limit" => validity_period
                }



                req_body3 = {
                  # "address-list": "any",
                  # "address-pool": "any",
                
                  
                  "name": "#{name}",
                 
                  # "rate-limit": "any",
                  "session-timeout": "#{validity_period}",
                  # "shared-users": "any",
                 
                
              
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
          # req3.body = req_body3.to_json

          req3.body =   if params[:download_limit].present? && params[:upload_limit].present?
           req_body4.to_json
      
         
      
           else
             req_body3.to_json
           end

          # response = Net::HTTP.start(uri.hostname, uri.port){|http| http.request(req)}
          # response2 = Net::HTTP.start(uri2.hostname, uri2.port){|http| http.request(req2)} 
          response3 = Net::HTTP.start(uri3.hostname, uri3.port){|http| http.request(req3)}

          # if response.is_a?(Net::HTTPSuccess) && response2.is_a?(Net::HTTPSuccess) && response3.is_a?(Net::HTTPSuccess)

        if response3.is_a?(Net::HTTPSuccess)
          @hotspot_package.update(hotspot_package_params)
          render json: @hotspot_package
        else
          puts "Failed to update profile and limitation : #{response3.code} - #{response3.message}"

          render json: { error: "Failed to update package" }, status: :unprocessable_entity

        end
      
      else
      
        render json: { error: " limitation ID, or profile ID not found in the package" }, status: :unprocessable_entity

      end
      else
        render json: { error: 'Unprocesable entity' }, status: :unprocessable_entity
      end
    
  end





  # DELETE /hotspot_packages/1 or /hotspot_packages/1.json
  def destroy
    # @hotspot_package.destroy!

  
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
    
        # profile_limitation_id = @hotspot_package.profile_limitation_id
        # limitation_id = @hotspot_package.limitation_id
        # profile_id = @hotspot_package.profile_id
        user_profile_id = @hotspot_package.user_profile_id
        # if  profile_id.present?  && limitation_id.present? && profile_limitation_id.present? && user_profile_id.present?

        if user_profile_id.present?
          # uri = URI("http://#{router_ip_address}/rest/user-manager/profile/#{profile_id}")
          # uri2 = URI("http://#{router_ip_address}/rest/user-manager/limitation/#{limitation_id}")
          ur4 = URI("http://#{router_ip_address}/rest/ip/hotspot/user/profile/#{user_profile_id}")
          
    
          # request = Net::HTTP::Delete.new(uri)
          # request2 = Net::HTTP::Delete.new(uri2)
          request4 = Net::HTTP::Delete.new(ur4)
    
          # request.basic_auth router_username, router_password
          # request2.basic_auth router_username, router_password
          request4.basic_auth router_username, router_password
    
          # response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
          # response2 = Net::HTTP.start(uri2.hostname, uri2.port) { |http| http.request(request2) }
          response4 = Net::HTTP.start(ur4.hostname, ur4.port) { |http| http.request(request4) }
    
          # if  response2.is_a?(Net::HTTPSuccess) && response.is_a?(Net::HTTPSuccess) && response4.is_a?(Net::HTTPSuccess)
          if response4.is_a?(Net::HTTPSuccess)
            @hotspot_package.destroy!
            head :no_content
          else
            render json: { error: "Failed to delete profile, limitation, and profile limitation from Mikrotik" }, status: :unprocessable_entity
          end
        else
          render json: { error: "Mikrotik ID, limitation ID, or profile limitation ID not found in the package" }, status: :unprocessable_entity
        end


        # profile_limitation_id = @hotspot_package.profile_limitation_id

        # uri3 = URI("http://#{router_ip_address}/rest/user-manager/profile-limitation/#{profile_limitation_id}")
        # request3 = Net::HTTP::Delete.new(uri3)

        # request3.basic_auth router_username, router_password

        # response3 = Net::HTTP.start(uri3.hostname, uri3.port) { |http| http.request(request3) }

        # if response3.is_a?(Net::HTTPSuccess)
        #   puts 'profile limitation deleted'
        # else
        #   "failed  to delete #{response4.code} - #{response4.message}"
        # end
      else
        render json: { error: "Package not found" }, status: :not_found
      end
  end



  private



  def fetch_profile_limitation_id
  

    # router_name = session[:router_name]
    router_name = params[:router_name]
  
          nas_router = NasRouter.find_by(name: router_name)
        if nas_router
          router_ip_address = nas_router.ip_address
            router_password = nas_router.password
           router_username = nas_router.username
        
        else
        
          puts 'router not found'
        end
  
        name = params[:name]
  
    user1 = router_username
    password = router_password
    request_body3 = {
      
    profile:  name,
    limitation: name
    }
    
    
    
    uri = URI("http://#{router_ip_address}/rest/user-manager/profile-limitation/add")
    request = Net::HTTP::Post.new(uri)
    request.basic_auth user1, password
    request.body = request_body3.to_json
    
    request['Content-Type'] = 'application/json'
    
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      return data['ret']
    else
      puts "Failed to post profile limitation: #{response.code} - #{response.message}"
    end
        
    
  
  end






   def fetch_profile_id_from_mikrotik
        
        # router_name = session[:router_name]
  router_name = params[:router_name]
        nas_router = NasRouter.find_by(name: router_name)
      if nas_router
        router_ip_address = nas_router.ip_address
          router_password = nas_router.password
         router_username = nas_router.username
      
      else
      
        puts 'router not found'
      end
    
  
 
    name = params[:name]
     
      validity = params[:validity]
      validity_period_units = params[:validity_period_units]
      price =  params[:price]
    
  
    
   validity_period =   if validity_period_units == 'days'
    "#{validity}d 00:00:00"
  
    elsif validity_period_units == 'hours'
       "#{validity}:00:00"


    elsif validity_period_units == 'minutes'
      "00:#{validity}:00"
    
    end
  
    
  
    
    request_body1={
      name: name,
    validity: validity_period ,
    price: price
    }
  
  
  uri = URI("http://#{router_ip_address}/rest/user-manager/profile/add")
  request = Net::HTTP::Post.new(uri)
  
  request.basic_auth router_username, router_password
  request.body = request_body1.to_json
  
  request['Content-Type'] = 'application/json'
  
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      return data['ret']
     

    else
      puts "Failed to profile: #{response.code} - #{response.message}"
    end
  

        end



        def fetch_user_profile_id_from_mikrotik
          # /ip/hotspot/user/profile/add
          # router_name = session[:router_name]
          router_name = params[:router_name]
          validity = params[:validity]
          nas_router = NasRouter.find_by(name: router_name)
        if nas_router
          router_ip_address = nas_router.ip_address
            router_password = nas_router.password
           router_username = nas_router.username
        
        else
        
          puts 'router not found'
        end
        validity_period_units = params[:validity_period_units]

        validity_period =   if validity_period_units == 'days'
          "#{validity}d 00:00:00"
        
          elsif validity_period_units == 'hours'
             "#{validity}:00:00"
              elsif validity_period_units == 'minutes'
    "00:#{validity}:00"
          
          end


          download_limit = params[:download_limit] 
          upload_limit = params[:upload_limit] 



          
        name = params[:name]
        request_body2 = {
          # "address-list": "any",
          # "address-pool": "any",
        
          
          "name": "#{name}",
         
          "rate-limit": "#{upload_limit}M/#{download_limit}M",
          "session-timeout": "#{validity_period}",
          # "shared-users": "any",
         
        
      
      }


      request_body = {
        # "address-list": "any",
        # "address-pool": "any",
      
        
        "name": "#{name}",
       
        "session-timeout": "#{validity_period}",
        # "shared-users": "any",
       
      
    
    }
    
      # request_body2.to_json
    uri = URI("http://#{router_ip_address}/rest/ip/hotspot/user/profile/add")
    request = Net::HTTP::Post.new(uri)
    
    request.basic_auth router_username, router_password
    request.body =   if params[:download_limit].present? && params[:upload_limit].present?
      request_body2.to_json

   

     else
       request_body.to_json
     end
    

    request['Content-Type'] = 'application/json'
    
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
            return data['ret']
  
    else
      puts "Failed to fetch user profile id : #{response.code} - #{response.message}"
    end


        end








        def fetch_limitation_id_from_mikrotik
  
          router_name = params[:router_name]
        
                nas_router = NasRouter.find_by(name: router_name)
              if nas_router
                router_ip_address = nas_router.ip_address
                  router_password = nas_router.password
                 router_username = nas_router.username
              
              else
              
                puts 'router not found'
              end
            
          
            
            
           download_limit = params[:download_limit] if params[:download_limit].present?
              upload_limit = params[:upload_limit] if params[:upload_limit].present?
           
            upload_burst_limit = params[:upload_burst_limit]
            download_burst_limit = params[:download_burst_limit]
                validity = params[:validity]
                validity_period_units = params[:validity_period_units]
            name = params[:name]
        
            
           validity_period =   if validity_period_units == 'days'
            "#{validity}d 00:00:00"
          
            elsif validity_period_units == 'hours'
               "#{validity}:00:00"
                elsif validity_period_units == 'minutes'
      "00:#{validity}:00"
            
            end
          
            
          
            request_body2 = {
              
              # "download-limit" => download_limit,
              # "upload-limit" => upload_limit,
          "name" => name,
          # "rate-limit-rx" => "#{upload_limit}M",
          # "rate-limit-tx" => "#{download_limit}M",
          # "rate-limit-burst-rx" => "#{upload_burst_limit}M",
          # "rate-limit-burst-tx" => "#{download_burst_limit}M",
          "uptime-limit" => validity_period
            }
          
          
          uri = URI("http://#{router_ip_address}/rest/user-manager/limitation/add")
          request = Net::HTTP::Post.new(uri)
          
          request.basic_auth router_username, router_password
          request.body = request_body2.to_json
          
          request['Content-Type'] = 'application/json'
          
          response = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(request)
          end
          
          if response.is_a?(Net::HTTPSuccess)
            data = JSON.parse(response.body)
                  return data['ret']
        
          else
            puts "Failed to post limitation_id : #{response.code} - #{response.message}"
          end
              
          
        end





    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_package
      @hotspot_package = HotspotPackage.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def hotspot_package_params
      params.require(:hotspot_package).permit(:name, :price, :download_limit, :upload_limit,
       :account_id, :tx_rate_limit, :rx_rate_limit, :validity_period_units, :download_burst_limit, 
       :upload_burst_limit, :validity,)
    end
end



