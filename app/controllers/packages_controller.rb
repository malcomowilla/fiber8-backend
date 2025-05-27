class PackagesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found_response

  load_and_authorize_resource except: [:allow_get_packages]

  require 'net/http'
  require 'uri'
  require 'json'

    # before_action :authenticate_user!, only: [:index]



  set_current_tenant_through_filter

  before_action :set_tenant
  
  def set_tenant

    host = request.headers['X-Subdomain'] 
    # Rails.logger.info("Setting tenant for host: #{host}")
  
    @account = Account.find_by(subdomain: host)
    set_current_tenant(@account)
  
    unless @account
      render json: { error: 'Invalid tenant' }, status: :not_found
    end
    
  end
  
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
   
      render json: @package, each_serializer:  PackageSerializer
    end
  
  
    def allow_get_packages
      
      @package = Package.all
   
      render json: @package, each_serializer:  PackageSerializer
    end
  
            
            # def create
          
            #       # puts @package.inspect  

             
            #       host = request.headers['X-Subdomain'] 

            #       if host === 'demo'

            #         if Package.exists?(name: params[:name])
            #           render json: { error: "ip pool already exists" }, status: :unprocessable_entity
            #           return
                      
            #         end
                    
    
                    
            #         if params[:name].blank?
            #           render json: { error: "package name is required" }, status: :unprocessable_entity
            #           return
            #         end
                    
            #         if params[:download_limit].blank?
            #           render json: { error: "download limit is required" }, status: :unprocessable_entity
            #           return
            #         end
                    
            #         if params[:upload_limit].blank?
            #           render json: { error: "upload limit is required" }, status: :unprocessable_entity
            #           return
            #         end
                    
            #         if params[:price].blank?
            #           render json: { error: "price is required" }, status: :unprocessable_entity
            #           return
            #         end
                    
    
    
            #         @package = Package.new(package_params)

            #         @package.save
            #         render json: @package, serializer: PackageSerializer
            #       else
            #         use_radius = ActsAsTenant.current_tenant.router_setting.use_radius
            #         @package = Package.new(package_params)
            #         if use_radius
            #           @package = Package.new(package_params)
            #           profile_id= fetch_profile_id_from_mikrotik(@package.name)
            #           limitation_id = fetch_limitation_id_from_mikrotik(@package.name)
      
      
      
                     
                      
            #           if Package.exists?(name: params[:name])
            #             render json: { error: "ip pool already exists" }, status: :unprocessable_entity
            #             return
                        
            #           end
                      
      
                      
            #           if params[:name].blank?
            #             render json: { error: "package name is required" }, status: :unprocessable_entity
            #             return
            #           end
                      
            #           if params[:download_limit].blank?
            #             render json: { error: "download limit is required" }, status: :unprocessable_entity
            #             return
            #           end
                      
            #           if params[:upload_limit].blank?
            #             render json: { error: "upload limit is required" }, status: :unprocessable_entity
            #             return
            #           end
                      
            #           if params[:price].blank?
            #             render json: { error: "price is required" }, status: :unprocessable_entity
            #             return
            #           end
                      
      
      
      
      
      
            #             if  profile_id && limitation_id &&  @package.save
        
                       
            #             if profile_id && limitation_id 
            #                   @package.update(mikrotik_id: profile_id, limitation_id: limitation_id,)
            #                   profile_limitation_id =  fetch_profile_limitation_id(@package.name)
            #       @package.update(profile_limitation_id: profile_limitation_id)
        
            #                       render json:  @package, status: :created
        
            #             else
            #                     render json: { error: 'Failed to obtain the  ids' }, status: :unprocessable_entity
        
            #             end
            #           else
            #             render json: {error: 'Package Already Created'}, status: :unprocessable_entity
                      
                    
            #           end
                    
            #         else
      
      
                  
      
      
            #           if params[:ip_pool].blank?
            #             render json: { error: "ip pool is required" }, status: :unprocessable_entity
            #             return
            #           end
                      
            #           if Package.exists?(name: params[:name])
            #             render json: { error: "ip pool already exists" }, status: :unprocessable_entity
            #             return
                        
            #           end
                      
      
                      
            #           if params[:name].blank?
            #             render json: { error: "package name is required" }, status: :unprocessable_entity
            #             return
            #           end
                      
            #           if params[:download_limit].blank?
            #             render json: { error: "download limit is required" }, status: :unprocessable_entity
            #             return
            #           end
                      
            #           if params[:upload_limit].blank?
            #             render json: { error: "upload limit is required" }, status: :unprocessable_entity
            #             return
            #           end
                      
            #           if params[:price].blank?
            #             render json: { error: "price is required" }, status: :unprocessable_entity
            #             return
            #           end
                      
                      
            #           ppoe_profile_id = fetch_ppp_profile_id_from_mikrotik
      
      
      
            #           if ppoe_profile_id && @package.save
            #             @package.update(ppoe_profile_id: ppoe_profile_id)
            #             render json:  @package, status: :created
            #           else
            #             render json: { error: 'Failed to obtain the  ppoe profile id from mikrotik' }, status: :unprocessable_entity
            #           end
      
            #         end

            #       end
             
            
                
            #   end

    










              def create
                # Validate package attributes
                if Package.exists?(name: params[:package][:name])
                  render json: { error: "package name already exists" }, status: :unprocessable_entity
                  return
                  
                end
                

                
                if params[:package][:name].blank?
                  render json: { error: "package name is required" }, status: :unprocessable_entity
                  return
                end
                
                if params[:package][:download_limit].blank?
                  render json: { error: "download limit is required" }, status: :unprocessable_entity
                  return
                end
                
                if params[:package][:upload_limit].blank?
                  render json: { error: "upload limit is required" }, status: :unprocessable_entity
                  return
                end
                
                if params[:package][:price].blank?
                  render json: { error: "price is required" }, status: :unprocessable_entity
                  return
                end
                
              
                @package = Package.new(package_params)
                
                if @package.save
                  # Call the method to update FreeRADIUS policies after saving the package
                  update_freeradius_policies(@package)
                  render json: @package, serializer: PackageSerializer
                else
                  render json: { error: @package.errors.full_messages }, status: :unprocessable_entity
                end
              end





            
          #     def update_package
          #               # session[:router_name] = params[:router_name]
          #               host = request.headers['X-Subdomain'] 
                        
          #               if host === 'demo'
          #                 package = Package.find_by(id: params[:id])
          #                 if package
          #                   package.update(package_params)
          #                   render json: package

          #                 else
          #                   render json: { error: 'package not found' }, status: :not_found
                            
          #                 end
          #               else

          #                 package = Package.find_by(id: params[:id])
          #                 use_radius = ActsAsTenant.current_tenant.router_setting.use_radius
          
          #                   if use_radius
          
          #                     if package
          #                       router_name = params[:router_name]
          #                     nas_router = NasRouter.find_by(name: router_name)
          #                     if nas_router
          #                       router_ip_address = nas_router.ip_address
          #                       router_password = nas_router.password
          #                       router_username = nas_router.username
          #                     else
          #                       puts 'router not found'
          #                     end
            
            
            
            
            
          #                     mikrotik_id = package.mikrotik_id
          #                     limitation_id = package.limitation_id
          #                     if mikrotik_id.present? && limitation_id.present?
                                
          #                       download_limit = package_params[:download_limit]
          #                       upload_limit = package_params[:upload_limit]
                            
          #                     upload_burst_limit = package_params[:upload_burst_limit]
          #                     download_burst_limit = package_params[:download_burst_limit]
          #                         validity = package_params[:validity]
                                      
          #                   price =  package_params[:price]
                          
          #                         validity_period_units = package_params[:validity_period_units]
          #                     name = package_params[:name]
                          
                              
          #                   validity_period  =   if validity_period_units == 'days'
          #                     "#{validity}d 00:00:00"
                            
          #                     elsif validity_period_units == 'hours'
          #                       "#{validity}:00:00"
                              
          #                     end
            
            
            
            
          #                       req_body={
          #                         "name" => name,
            
          #                         :price => price,
          #                         :validity => validity_period
            
          #                       }
            
                                  
                            
          #                               req_body2 = {
                                          
          #                                 "download-limit" => download_limit,
          #                                 "upload-limit" => upload_limit,
          #                             "name" => name,
          #                             "rate-limit-rx" => "#{upload_limit}M",
          #                             "rate-limit-tx" => "#{download_limit}M",
          #                             "rate-limit-burst-rx" => "#{upload_burst_limit}M",
          #                             "rate-limit-burst-tx" => "#{download_burst_limit}M",
          #                             "uptime-limit" => validity_period
          #                               }
                                        
          #                               begin
          #                               uri = URI("http://#{router_ip_address}/rest/user-manager/profile/#{mikrotik_id}") 
          #                               uri2 = URI("http://#{router_ip_address}/rest/user-manager/limitation/#{limitation_id}") 
          #                               req = Net::HTTP::Patch.new(uri)
          #                               req2 = Net::HTTP::Patch.new(uri2)
                                           
            
          #                                   req.basic_auth router_username, router_password
          #                                   req2.basic_auth router_username, router_password
                                           
          #                                   req['Content-Type'] = 'application/json'
          #                                   req2['Content-Type'] = 'application/json'
            
          #                         req.body = req_body.to_json
          #                         req2.body = req_body2.to_json
            
          #                         response = Net::HTTP.start(uri.hostname, uri.port){|http| http.request(req)}
          #                         response2 = Net::HTTP.start(uri2.hostname, uri2.port){|http| http.request(req2)} 
            
            
          #                       if response.is_a?(Net::HTTPSuccess) && response2.is_a?(Net::HTTPSuccess) 
          #                         package.update(package_params)
          #                         render json: package
          #                       else
          #                         puts "Failed to update profile and limitation : #{response.code} - #{response.message}"
            
          #                         render json: { error: "Failed to update package" }, status: :unprocessable_entity
            
          #                       end
            
            
          #     rescue Net::OpenTimeout, Net::ReadTimeout
          #       render json: { error: "Request timed out while connecting to the router. Please check if the router is online." }, status: :gateway_timeout
          #     rescue Errno::ECONNREFUSED
          #       render json: { error: "Failed to connect to the router at #{router_ip_address}. Connection refused." }, status: :bad_gateway
          #     rescue StandardError => e
          #       render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
              
          #                       end
            
                              
          #                     else
                              
          #                       render json: { error: "Mikrotik ID, limitation ID, or profile limitation ID not found in the package" }, status: :unprocessable_entity
            
          #                     end
            
                              
            
          #                     else
          #                       render json: { error: 'Unprocesable entity' }, status: :unprocessable_entity
          #                     end
          
          
          #                   else
          #                       if package
          #                       router_name = params[:router_name]
          #                     nas_router = NasRouter.find_by(name: router_name)
          #                     if nas_router
          #                       router_ip_address = nas_router.ip_address
          #                       router_password = nas_router.password
          #                       router_username = nas_router.username
          #                     else
          #                       puts 'router not found'
          #                     end
            
            
            
            
            
          #                   ppoe_profile_id = package.ppoe_profile_id
          #                     if ppoe_profile_id.present?
                                
          # validity = package_params[:validity]
          
          # validity = package_params[:validity]
          #       validity_period_units = package_params[:validity_period_units]
              
          #    download_limit = package_params[:download_limit]
          #    upload_limit = package_params[:upload_limit]
          #    name = package_params[:name]
            
              
          #    validity_period =   if validity_period_units == 'days'
          #     "#{validity}d 00:00:00"
            
          #     elsif validity_period_units == 'hours'
          #        "#{validity}:00:00"
              
          #     end
          
          # ip_pool = package_params[:ip_pool]
          # # pool_name = package_params[:pool_name]
          #     request_body = {
          #       # "comment": "any",
          #       # "dns-server": "any",
          #       "local-address": "#{ip_pool}",
          #       "name": "#{name}",
               
          #       # "only-one": "any",
                
          #       "rate-limit": "#{upload_limit}/#{download_limit}",
          #       "remote-address": "#{ip_pool}",
          #       "session-timeout": "#{validity_period}",
          #       # "use-encryption": "any",
               
               
          #     }
                               
            
                                  
                            
                                       
                                        
          #                               begin
          #                               uri = URI("http://#{router_ip_address}/rest/ppp/profile/#{ppoe_profile_id}") 
          #                               req = Net::HTTP::Patch.new(uri)
                                           
            
          #                                   req.basic_auth router_username, router_password
                                           
          #                                   req['Content-Type'] = 'application/json'
            
          #                         req.body = request_body.to_json
            
          #                         response = Net::HTTP.start(uri.hostname, uri.port){|http| http.request(req)}
            
            
          #                       if response.is_a?(Net::HTTPSuccess)
          #                         package.update(package_params)
          #                         render json: package
          #                       else
          #                         puts "Failed to update ppoe profile : #{response.code} - #{response.message}"
            
          #                         render json: { error: "Failed to update package" }, status: :unprocessable_entity
            
          #                       end
            
            
          #     rescue Net::OpenTimeout, Net::ReadTimeout
          #       render json: { error: "Request timed out while connecting to the router. Please check if the router is online." }, status: :gateway_timeout
          #     rescue Errno::ECONNREFUSED
          #       render json: { error: "Failed to connect to the router at #{router_ip_address}. Connection refused." }, status: :bad_gateway
          #     rescue StandardError => e
          #       render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
              
          #                       end
            
                              
          #                     else
                              
          #                       render json: { error: "Mikrotik ID, limitation ID, or profile limitation ID not found in the package" }, status: :unprocessable_entity
            
          #                     end
            
                              
            
          #                     else
          #                       render json: { error: 'Unprocesable entity' }, status: :unprocessable_entity
          #                     end
          #                   end
                           
          #               end
                                      
          #     end








          def update_package

 package = Package.find_by(id: params[:id])
                          if package
                            package.update(package_params)
                            update_freeradius_policies(package)

                            render json: package

                          else
                            render json: { error: 'package not found' }, status: :not_found
                            
                          end

          end




    
  #   def delete


  #     host = request.headers['X-Subdomain'] 

  #     if host == 'demo'
  #       package = Package.find_by(id: params[:id])
  #       if package
  #         package.destroy
  #         head :no_content
  #       else
  #         render json: { error: 'package not found' }, status: :not_found
  #       end
  #     else

  # package = Package.find_by(id: params[:id])
  #     use_radius = ActsAsTenant.current_tenant.router_setting.use_radius


  #     if  use_radius
          
  # unless package
  #   return render json: { error: "Package not found" }, status: :not_found
  # end

  # router_name = params[:router_name]
  # nas_router = NasRouter.find_by(name: router_name)

  # unless nas_router
  #   return render json: { error: "Router not found" }, status: :not_found
  # end

  # router_ip_address = nas_router.ip_address
  # router_password = nas_router.password
  # router_username = nas_router.username

  # mikrotik_id = package.mikrotik_id
  # limitation_id = package.limitation_id

  # unless mikrotik_id.present? && limitation_id.present?
  #   return render json: { error: "Mikrotik ID or Limitation ID missing in package" }, status: :unprocessable_entity
  # end

  # begin
  #   uri = URI("http://#{router_ip_address}/rest/user-manager/profile/#{mikrotik_id}")
  #   uri2 = URI("http://#{router_ip_address}/rest/user-manager/limitation/#{limitation_id}")

  #   request = Net::HTTP::Delete.new(uri)
  #   request2 = Net::HTTP::Delete.new(uri2)

  #   request.basic_auth(router_username, router_password)
  #   request2.basic_auth(router_username, router_password)

  #   response = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 10, read_timeout: 10) { |http| http.request(request) }
  #   response2 = Net::HTTP.start(uri2.hostname, uri2.port, open_timeout: 10, read_timeout: 10) { |http| http.request(request2) }

  #   if response.is_a?(Net::HTTPSuccess) && response2.is_a?(Net::HTTPSuccess)
  #     package.destroy
  #     head :no_content
  #   else
  #     error_message = "Failed to delete: Profile - #{response.code} #{response.message}, Limitation - #{response2.code} #{response2.message}"
  #     render json: { error: error_message }, status: :unprocessable_entity
  #   end

  # rescue Net::OpenTimeout, Net::ReadTimeout
  #   render json: { error: "Request timed out while connecting to the router. Please check if the router is online." }, status: :gateway_timeout
  # rescue Errno::ECONNREFUSED
  #   render json: { error: "Failed to connect to the router at #{router_ip_address}. Connection refused." }, status: :bad_gateway
  # rescue StandardError => e
  #   render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
  

        
  #       profile_limitation_id = package.profile_limitation_id

  #       uri3 = URI("http://#{router_ip_address}/rest/user-manager/profile-limitation/#{profile_limitation_id}")
  #       request3 = Net::HTTP::Delete.new(uri3)

  #       request3.basic_auth router_username, router_password

  #       response3 = Net::HTTP.start(uri3.hostname, uri3.port) { |http| http.request(request3) }

  #       if response3.is_a?(Net::HTTPSuccess)
  #         head :no_content
  #       else
  #         'failed  to delete'
  #       end
  #     else
  #       render json: { error: "Package not found" }, status: :not_found
  #     end

  #     else
      
  # unless package
  #   return render json: { error: "Package not found" }, status: :not_found
  # end

  # router_name = params[:router_name]
  # nas_router = NasRouter.find_by(name: router_name)

  # unless nas_router
  #   return render json: { error: "Router not found" }, status: :not_found
  # end

  # router_ip_address = nas_router.ip_address
  # router_password = nas_router.password
  # router_username = nas_router.username

  # ppoe_profile_id = package.ppoe_profile_id

  # unless ppoe_profile_id.present?
  #   return render json: { error: "ppoe profile id missing in package" }, status: :unprocessable_entity
  # end

  # begin
  #   uri = URI("http://#{router_ip_address}/rest/ppp/profile/#{ppoe_profile_id}")

  #   request = Net::HTTP::Delete.new(uri)

  #   request.basic_auth(router_username, router_password)

  #   response = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 10, read_timeout: 10) { |http| http.request(request) }

  #   if response.is_a?(Net::HTTPSuccess)
  #     package.destroy
  #     head :no_content
  #   else
  #     error_message = "Failed to delete ppp Profile - #{response.code} #{response.message}, Limitation - #{response2.code} #{response2.message}"
  #     render json: { error: error_message }, status: :unprocessable_entity
  #   end

  # rescue Net::OpenTimeout, Net::ReadTimeout
  #   render json: { error: "Request timed out while connecting to the router. Please check if the router is online." }, status: :gateway_timeout
  # rescue Errno::ECONNREFUSED
  #   render json: { error: "Failed to connect to the router at #{router_ip_address}. Connection refused." }, status: :bad_gateway
  # rescue StandardError => e
  #   render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
  # end
  #     end
  #     end 
  #   end
    
  
def delete
  @package = Package.find_by(id: params[:id])

  if @package.nil?
    return render json: { error: "pppoe package not found" }, status: :not_found
  end

  group_name = "pppoe_#{@package.name.parameterize(separator: '_')}"


  ActiveRecord::Base.transaction do
    # ✅ Delete related FreeRADIUS records
    RadGroupReply.where(groupname: group_name).destroy_all

    # ✅ Delete the HotspotPackage
    @package.destroy!
  end

  render json: { message: "Hotspot package deleted successfully" }, status: :ok
rescue => e
  render json: { error: "Failed to delete hotspot package: #{e.message}" }, status: :unprocessable_entity
end



    def authenticate_user!
      
      @current_user ||= begin
          token = cookies.encrypted.signed[:jwt_user]
          if token  
            begin
              decoded_token = JWT.decode(token, 
               ENV['JWT_SECRET_KEY'])
            user_id = decoded_token[0]['user_id']
            @current_user = User.find_by(id: user_id)
              return @current_user if @current_user
            rescue JWT::DecodeError, JWT::ExpiredSignature => e
              Rails.logger.error "JWT Decode Error: #{e}"
              render json: { error: 'Unauthorized' }, status: :unauthorized
            end
          end
          nil
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
      
      # "download-limit" => download_limit,
      # "upload-limit" => upload_limit,
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




def fetch_ppp_profile_id_from_mikrotik
  # /ppp/profile/add
  # 
  #  # router_name = session[:router_name]
  router_name = params[:router_name]
  nas_router = NasRouter.find_by(name: router_name)
if nas_router
  router_ip_address = nas_router.ip_address
    router_password = nas_router.password
   router_username = nas_router.username

else

  puts 'router not found'
  render json: { error: 'router not found' }, status: :not_found
end

validity = package_params[:validity]

validity = package_params[:validity]
      validity_period_units = package_params[:validity_period_units]
    
   download_limit = package_params[:download_limit]
   upload_limit = package_params[:upload_limit]
   name = package_params[:name]
  
    
   validity_period =   if validity_period_units == 'days'
    "#{validity}d 00:00:00"
  
    elsif validity_period_units == 'hours'
       "#{validity}:00:00"
    
    end

ip_pool = package_params[:ip_pool]
# pool_name = package_params[:pool_name]
    request_body = {
      # "comment": "any",
      # "dns-server": "any",
      "local-address": "#{ip_pool}",
      "name": "#{name}",
     
      # "only-one": "any",
      
      "rate-limit": "#{upload_limit}M/#{download_limit}M",
      "remote-address": "#{ip_pool}",
      "session-timeout": "#{validity_period}",
      # "use-encryption": "any",
     
     
    }



    

    uri = URI("http://#{router_ip_address }/rest/ppp/profile/add")
    request = Net::HTTP::Post.new(uri)
  
    request.basic_auth router_username, router_password
    request.body = request_body.to_json
    
  request['Content-Type'] = 'application/json'
  
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end


  if response.is_a?(Net::HTTPSuccess)
    data = JSON.parse(response.body)
    return data['ret']
  else
    puts "Failed to add ppoe profile: #{response.code} - #{response.message}"
  

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


def update_freeradius_policies(package)
  # Ensure the package is of type PppoePackage
  # return unless package.is_a?(PppoePackage)

  # Define the group name for PPPOE package
  group_name = "pppoe_#{package.name.parameterize(separator: '_')}"

  ActiveRecord::Base.transaction do
    # ✅ Update or create speed limits in RadGroupReply for PPPOE
    rad_reply = RadGroupReply.find_or_initialize_by(groupname: group_name, radiusattribute: 'Mikrotik-Rate-Limit')
    rad_reply.update!(op: ':=', value: "#{package.upload_limit}M/#{package.download_limit}M")

    # ✅ Optionally handle validity or expiration if applicable
    # if package.validity.present?
    #   rad_check = RadGroupCheck.find_or_initialize_by(groupname: group_name, radiusattribute: 'Expiration')
    #   expiration_time = (Time.current + package.validity.days).strftime("%d %b %Y %H:%M:%S")
    #   rad_check.update!(op: ':=', value: expiration_time)
    # end




    

    # ✅ Optionally handle burst limits if applicable
    if package.upload_burst_limit.present? && package.download_burst_limit.present?
      burst_reply = RadGroupReply.find_or_initialize_by(groupname: group_name,
       radiusattribute: 'Mikrotik-Burst-Limit')
      burst_reply.update!(op: ':=', value: "#{package.upload_burst_limit}M/#{package.download_burst_limit}M")
    end
  end
end




      def package_params
        params.require(:package).permit(:name, :download_limit, :upload_limit, :price,
         :validity, 
        :upload_burst_limit,
        :package,
        :download_burst_limit,  :validity_period_units, :router_name,
        :ip_pool
         )
      end
  
  
  def not_found_response
    render json: { error: "Package not found" }, status: :not_found
  end
end
