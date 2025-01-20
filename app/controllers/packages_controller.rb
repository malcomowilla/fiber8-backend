class PackagesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found_response

  
  require 'net/http'
  require 'uri'
  require 'json'



  # set_current_tenant_through_filter

  # before_action :set_my_tenant
  
  
  
    # def set_my_tenant
    #   set_current_tenant(current_user.account)
    # end
  
    def index
     
       
      
    #   router_name = session[:router_name]
  
    #   nas_router = NasRouter.find_by(name: router_name)
    # if nas_router
    #   router_ip_address = nas_router.ip_address
    #     router_password = nas_router.password
    #    router_username = nas_router.username
    #    puts router_username 
    
    #    user1 = router_username
    #    password = router_password
    # else
    
    #   puts 'router not found'
    # end
     

    
    #   uri = URI("http://#{router_ip_address}/rest/user-manager/limitation")
    #   request = Net::HTTP::Get.new(uri)
    #   request.basic_auth user1, password
      
      
    #   response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    #     http.request(request)
    #   end
      
    #     if response.is_a?(Net::HTTPSuccess)
    #     data = JSON.parse(response.body)
    # puts data
    
    #   else
    #     puts "Failed to fetch limitation: #{response.code} - #{response.message}"
    #   end
    
    
      @package = Package.all
   
      render json: @package, each_serializer:  PackageRouterSerializer
    end
  
  
  
            
            def create
          
                  puts @package.inspect  

              
              @package = Package.new(package_params)
          
                if @package.save

                profile_id= fetch_profile_id_from_mikrotik(@package.name)
                limitation_id = fetch_limitation_id_from_mikrotik(@package.name)
                if profile_id && limitation_id 
                      @package.update(mikrotik_id: profile_id, limitation_id: limitation_id,)
                      profile_limitation_id =  fetch_profile_limitation_id(@package.name)
          @package.update(profile_limitation_id: profile_limitation_id)

                          render json:  @package, status: :created

                else
                        render json: { error: 'Failed to obtain the  ids' }, status: :unprocessable_entity

                end
              else
                render json: {error: 'Package Already Created'}, status: :unprocessable_entity
              
            
              end
            
                
              end

    


            
              def update_package
                        # session[:router_name] = params[:router_name]

                package = Package.find_by(id: params[:id])
            
                  
                  if package
                    router_name = params[:router_name]
                  nas_router = NasRouter.find_by(name: router_name)
                  if nas_router
                    router_ip_address = nas_router.ip_address
                    router_password = nas_router.password
                    router_username = nas_router.username
                  else
                    puts 'router not found'
                  end





                  mikrotik_id = package.mikrotik_id
                  limitation_id = package.limitation_id
                  if mikrotik_id.present? && limitation_id.present?
                    
                    download_limit = package_params[:download_limit]
                    upload_limit = package_params[:upload_limit]
                
                  upload_burst_limit = package_params[:upload_burst_limit]
                  download_burst_limit = package_params[:download_burst_limit]
                      validity = package_params[:validity]
                          
                price =  package_params[:price]
              
                      validity_period_units = package_params[:validity_period_units]
                  name = package_params[:name]
              
                  
                validity_period  =   if validity_period_units == 'days'
                  "#{validity}d 00:00:00"
                
                  elsif validity_period_units == 'hours'
                    "#{validity}:00:00"
                  
                  end




                    req_body={
                      "name" => name,

                      :price => price,
                      :validity => validity_period

                    }

                      
                
                            req_body2 = {
                              
                              "download-limit" => download_limit,
                              "upload-limit" => upload_limit,
                          "name" => name,
                          "rate-limit-rx" => "#{upload_limit}M",
                          "rate-limit-tx" => "#{download_limit}M",
                          "rate-limit-burst-rx" => "#{upload_burst_limit}M",
                          "rate-limit-burst-tx" => "#{download_burst_limit}M",
                          "uptime-limit" => validity_period
                            }
                            uri = URI("http://#{router_ip_address}/rest/user-manager/profile/#{mikrotik_id}") 
                            uri2 = URI("http://#{router_ip_address}/rest/user-manager/limitation/#{limitation_id}") 
                            req = Net::HTTP::Patch.new(uri)
                            req2 = Net::HTTP::Patch.new(uri2)
                               

                                req.basic_auth router_username, router_password
                                req2.basic_auth router_username, router_password
                               
                                req['Content-Type'] = 'application/json'
                                req2['Content-Type'] = 'application/json'

                      req.body = req_body.to_json
                      req2.body = req_body2.to_json

                      response = Net::HTTP.start(uri.hostname, uri.port){|http| http.request(req)}
                      response2 = Net::HTTP.start(uri2.hostname, uri2.port){|http| http.request(req2)} 


                    if response.is_a?(Net::HTTPSuccess) && response2.is_a?(Net::HTTPSuccess) 
                      package.update(package_params)
                      render json: package
                    else
                      puts "Failed to update profile and limitation : #{response.code} - #{response.message}"

                      render json: { error: "Failed to update package" }, status: :unprocessable_entity

                    end
                  
                  else
                  
                    render json: { error: "Mikrotik ID, limitation ID, or profile limitation ID not found in the package" }, status: :unprocessable_entity

                  end
                  else
                    render json: { error: 'Unprocesable entity' }, status: :unprocessable_entity
                  end
              
              end


    
    def delete
      package = Package.find_by(id: params[:id])
    
      if package
        router_name = session[:router_name]
        nas_router = NasRouter.find_by(name: router_name)
        if nas_router
          router_ip_address = nas_router.ip_address
          router_password = nas_router.password
          router_username = nas_router.username
        else
          puts 'router not found'
        end
    
        mikrotik_id = package.mikrotik_id
        limitation_id = package.limitation_id
    
        if mikrotik_id.present?  && limitation_id.present?
          uri = URI("http://#{router_ip_address}/rest/user-manager/profile/#{mikrotik_id}")
          uri2 = URI("http://#{router_ip_address}/rest/user-manager/limitation/#{limitation_id}")
    
          request = Net::HTTP::Delete.new(uri)
          request2 = Net::HTTP::Delete.new(uri2)
    
          request.basic_auth router_username, router_password
          request2.basic_auth router_username, router_password
    
          response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
          response2 = Net::HTTP.start(uri2.hostname, uri2.port) { |http| http.request(request2) }
    
          if  response2.is_a?(Net::HTTPSuccess) && response.is_a?(Net::HTTPSuccess)
            package.destroy
            head :no_content
          else
            render json: { error: "Failed to delete profile, limitation, and profile limitation from Mikrotik" }, status: :unprocessable_entity
          end
        else
          render json: { error: "Mikrotik ID, limitation ID, or profile limitation ID not found in the package" }, status: :unprocessable_entity
        end
        profile_limitation_id = package.profile_limitation_id

        uri3 = URI("http://#{router_ip_address}/rest/user-manager/profile-limitation/#{profile_limitation_id}")
        request3 = Net::HTTP::Delete.new(uri3)

        request3.basic_auth router_username, router_password

        response3 = Net::HTTP.start(uri3.hostname, uri3.port) { |http| http.request(request3) }

        if response3.is_a?(Net::HTTPSuccess)
          puts 'profile limitation deleted'
        else
          'failed  to delete'
        end
      else
        render json: { error: "Package not found" }, status: :not_found
      end

      
    end
    
  
  
    private
      


def fetch_limitation_id_from_mikrotik(package_name)
  
  router_name = params[:router_name]

        nas_router = NasRouter.find_by(name: router_name)
      if nas_router
        router_ip_address = nas_router.ip_address
          router_password = nas_router.password
         router_username = nas_router.username
      
      else
      
        puts 'router not found'
      end
    
  
    
    
   download_limit = package_params[:download_limit]
      upload_limit = package_params[:upload_limit]
   
    upload_burst_limit = package_params[:upload_burst_limit]
    download_burst_limit = package_params[:download_burst_limit]
        validity = package_params[:validity]
        validity_period_units = package_params[:validity_period_units]
    name = package_params[:name]

    
   validity_period =   if validity_period_units == 'days'
    "#{validity}d 00:00:00"
  
    elsif validity_period_units == 'hours'
       "#{validity}:00:00"
    
    end
  
    
  
    request_body2 = {
      
      "download-limit" => download_limit,
      "upload-limit" => upload_limit,
  "name" => name,
  "rate-limit-rx" => "#{upload_limit}M",
  "rate-limit-tx" => "#{download_limit}M",
  "rate-limit-burst-rx" => "#{upload_burst_limit}M",
  "rate-limit-burst-tx" => "#{download_burst_limit}M",
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
    puts "Failed to post upload and download limit : #{response.code} - #{response.message}"
  end
      
  
end






        def fetch_profile_id_from_mikrotik(package_name)
        
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
    
  
 
    name = package_params[:name]
     
      validity = package_params[:validity]
      validity_period_units = package_params[:validity_period_units]
      price =  package_params[:price]
    
  
    
   validity_period =   if validity_period_units == 'days'
    "#{validity}d 00:00:00"
  
    elsif validity_period_units == 'hours'
       "#{validity}:00:00"
    
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
   


def fetch_profile_limitation_id(package_name)
  

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

      name = package_params[:name]

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




      def package_params
        params.require(:package).permit(:name, :download_limit, :upload_limit, :price, :validity, :upload_burst_limit,
        :download_burst_limit,  :validity_period_units, :router_name
         )
      end
  
  
  def not_found_response
    render json: { error: "Package not found" }, status: :not_found
  end
end
