class HotspotPackagesController < ApplicationController
  # before_action :set_hotspot_package, only: %i[ show edit update destroy ]

  # GET /hotspot_packages or /hotspot_packages.json

  load_and_authorize_resource :except => [:allow_get_hotspot_packages]


  set_current_tenant_through_filter

  before_action :set_tenant
  before_action :update_last_activity
  # /ip/hotspot/host?as-string=any&as-string-value=any&number=any&value-name=any
   




 def update_last_activity
if current_user
      current_user.update_column(:last_activity_active, Time.now.strftime('%Y-%m-%d %I:%M:%S %p'))
    end
    
  end

  





  def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
     ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
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
router_user = ''
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
user_mac = ''
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
#   def create


#     host = request.headers['X-Subdomain'] 


# if host === 'demo'
  


     
#   if HotspotPackage.exists?(name: params[:name])
#     render json: { error: "ip pool already exists" }, status: :unprocessable_entity
#     return
    
#   end
  

  
#   if params[:name].blank?
#     render json: { error: "package name is required" }, status: :unprocessable_entity
#     return
#   end
  
#   # if params[:download_limit].blank?
#   #   render json: { error: "download limit is required" }, status: :unprocessable_entity
#   #   return
#   # end
  
#   # if params[:upload_limit].blank?
#   #   render json: { error: "upload limit is required" }, status: :unprocessable_entity
#   #   return
#   # end
  
#   if params[:price].blank?
#     render json: { error: "price is required" }, status: :unprocessable_entity
#     return
#   end
#   @hotspot_package = HotspotPackage.new(hotspot_package_params)
#   # use_radius = ActsAsTenant.current_tenant.&router_setting&.use_radius



#     if @hotspot_package.save
    
           
#         render json: @hotspot_package, status: :created
#     else
#    render json: @hotspot_package.errors, status: :unprocessable_entity
#     end



  
  
# else
       
#   if HotspotPackage.exists?(name: params[:name])
#     render json: { error: "ip pool already exists" }, status: :unprocessable_entity
#     return
    
#   end
  

  
#   if params[:name].blank?
#     render json: { error: "package name is required" }, status: :unprocessable_entity
#     return
#   end
  
#   # if params[:download_limit].blank?
#   #   render json: { error: "download limit is required" }, status: :unprocessable_entity
#   #   return
#   # end
  
#   # if params[:upload_limit].blank?
#   #   render json: { error: "upload limit is required" }, status: :unprocessable_entity
#   #   return
#   # end
  
#   if params[:price].blank?
#     render json: { error: "price is required" }, status: :unprocessable_entity
#     return
#   end
#   @hotspot_package = HotspotPackage.new(hotspot_package_params)
#   use_radius = ActsAsTenant.current_tenant.router_setting.use_radius

#   if !use_radius


#     if @hotspot_package.save
#       # profile_id= fetch_profile_id_from_mikrotik
#       # limitation_id = fetch_limitation_id_from_mikrotik
#       # profile_limitation_id =  fetch_profile_limitation_id
#       user_profile_id = fetch_user_profile_id_from_mikrotik  
      
#       # if profile_id && limitation_id && profile_limitation_id && user_profile_id

#       if user_profile_id
#         # @hotspot_package.update(limitation_id: limitation_id,
#         #  profile_limitation_id: profile_limitation_id, profile_id: profile_id,user_profile_id: user_profile_id)

#         @hotspot_package.update(user_profile_id: user_profile_id)
#         render json: @hotspot_package, status: :created
#       else
#         render json: { error: 'Failed to obtain the  ids from mikrotik' }, status: :unprocessable_entity
#       end
        
#         # render json: @hotspot_package, status: :created
#     else
#    render json: @hotspot_package.errors, status: :unprocessable_entity
#     end

#   else

  
#     if @hotspot_package.save
#       profile_id= fetch_profile_id_from_mikrotik
#       limitation_id = fetch_limitation_id_from_mikrotik
#       profile_limitation_id =  fetch_profile_limitation_id
      
#       if profile_id && limitation_id && profile_limitation_id 

#         @hotspot_package.update(limitation_id: limitation_id,
#          profile_limitation_id: profile_limitation_id, profile_id: profile_id)

#         render json: @hotspot_package, status: :created
#       else
#         render json: { error: 'Failed to obtain the  ids from mikrotik' }, status: :unprocessable_entity
#       end
        
#         # render json: @hotspot_package, status: :created
#     else
#    render json: @hotspot_package.errors, status: :unprocessable_entity
#     end

#   end
# end

 
#   end



def create
     
  if HotspotPackage.exists?(name: params[:name])
    render json: { error: "ip pool already exists" }, status: :unprocessable_entity
    return
    
  end
  

  
  if params[:name].blank?
    render json: { error: "package name is required" }, status: :unprocessable_entity
    return
  end
  
  
  if params[:price].blank?
    render json: { error: "price is required" }, status: :unprocessable_entity
    return
  end
  @hotspot_package = HotspotPackage.new(hotspot_package_params)
  # use_radius = ActsAsTenant.current_tenant.&router_setting&.use_radius

  update_freeradius_policies(@hotspot_package)

    if @hotspot_package.save
    
           ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created hotspot package #{@hotspot_package.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
        render json: @hotspot_package, status: :created
    else
   render json: @hotspot_package.errors, status: :unprocessable_entity
    end
    
end



def update
  
  @hotspot_package = set_hotspot_package

  if @hotspot_package
    update_freeradius_policies(@hotspot_package)
    ActivtyLog.create(action: 'update', ip: request.remote_ip,
 description: "Updated hotspot package #{@hotspot_package.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
    @hotspot_package.update(hotspot_package_params)
    render json: @hotspot_package
  else
    render json: { error: 'hotspot package not found' }, status: :not_found
  end


end
  



  # DELETE /hotspot_packages/1 or /hotspot_packages/1.json
#   def destroy


#     host = request.headers['X-Subdomain'] 
#     if host === 'demo'
#       @hotspot_package = set_hotspot_package
#       @hotspot_package.destroy!
#       render json: { message: "Package deleted successfully" }
      
#     else

#       use_radius = ActsAsTenant.current_tenant.router_setting.use_radius
#     if use_radius == false
#     #    head :no_content 
#     @hotspot_package = set_hotspot_package
#        if @hotspot_package
#         router_name = params[:router_name]
#         nas_router = NasRouter.find_by(name: router_name)
#         if nas_router
#           router_ip_address = nas_router.ip_address
#           router_password = nas_router.password
#           router_username = nas_router.username
#         else
#           puts 'router not found'
#         end
    
#        user_profile_id = @hotspot_package.user_profile_id

#         if user_profile_id.present?
#           uri = URI("http://#{router_ip_address}/rest/user-manager/profile/#{profile_id}")
#           uri2 = URI("http://#{router_ip_address}/rest/user-manager/limitation/#{limitation_id}")
          
    
#           request = Net::HTTP::Delete.new(uri)
#           request2 = Net::HTTP::Delete.new(uri2)
    
#           request.basic_auth router_username, router_password
#           request2.basic_auth router_username, router_password
    
#           response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
#           response2 = Net::HTTP.start(uri2.hostname, uri2.port) { |http| http.request(request2) }
    
#           if  response2.is_a?(Net::HTTPSuccess) && response.is_a?(Net::HTTPSuccess) && response4.is_a?(Net::HTTPSuccess)
#             @hotspot_package.destroy!
#             head :no_content
#           else
#             render json: { error: "Failed to delete profile, limitation, and profile limitation from Mikrotik" }, status: :unprocessable_entity
#           end
#         else
#           render json: { error: "Mikrotik ID, limitation ID, or profile limitation ID not found in the package" }, status: :unprocessable_entity
#         end


#       else
#         render json: { error: "Package not found" }, status: :not_found
#       end


#     elsif use_radius == true


#  #    head :no_content 
#  @hotspot_package = set_hotspot_package
#  if @hotspot_package
#   router_name = params[:router_name]
#   nas_router = NasRouter.find_by(name: router_name)
#   if nas_router
#     router_ip_address = nas_router.ip_address
#     router_password = nas_router.password
#     router_username = nas_router.username
#   else
#     puts 'router not found'
#   end


  

#   profile_limitation_id = @hotspot_package.profile_limitation_id
#   limitation_id = @hotspot_package.limitation_id
#   profile_id = @hotspot_package.profile_id

#   if profile_id.present?  && limitation_id.present? && profile_limitation_id.present? 

#     uri = URI("http://#{router_ip_address}/rest/user-manager/profile/#{profile_id}")
#     uri2 = URI("http://#{router_ip_address}/rest/user-manager/limitation/#{limitation_id}")
    

#     request = Net::HTTP::Delete.new(uri)
#     request2 = Net::HTTP::Delete.new(uri2)

#     request.basic_auth router_username, router_password
#     request2.basic_auth router_username, router_password

#     response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
#     response2 = Net::HTTP.start(uri2.hostname, uri2.port) { |http| http.request(request2) }

#     if  response2.is_a?(Net::HTTPSuccess) && response.is_a?(Net::HTTPSuccess) 
#       @hotspot_package.destroy
#       head :no_content
#     else
#       render json: { error: "Failed to delete profile, limitation, and profile limitation from Mikrotik" }, status: :unprocessable_entity
#     end
#   else
#     render json: { error: "Mikrotik ID, limitation ID, or profile limitation ID not found in the package" }, status: :unprocessable_entity
#   end


#   profile_limitation_id = @hotspot_package.profile_limitation_id

#   uri3 = URI("http://#{router_ip_address}/rest/user-manager/profile-limitation/#{profile_limitation_id}")
#   request3 = Net::HTTP::Delete.new(uri3)

#   request3.basic_auth router_username, router_password

#   response3 = Net::HTTP.start(uri3.hostname, uri3.port) { |http| http.request(request3) }

#   if response3.is_a?(Net::HTTPSuccess)
#     puts 'profile limitation deleted'
#   else
#     "failed  to delete #{response4.code} - #{response4.message}"
#   end
# else
#   render json: { error: "Package not found" }, status: :not_found
# end



# end 
#     end

# end





def destroy
  @hotspot_package = HotspotPackage.find_by(id: params[:id])

  if @hotspot_package.nil?
    return render json: { error: "Hotspot package not found" }, status: :not_found
  end
ActivtyLog.create(action: 'delete', ip: request.remote_ip,
 description: "Deleted hotspot package #{@hotspot_package.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
  group_name = "hotspot_#{@hotspot_package.name.parameterize(separator: '_')}"


  ActiveRecord::Base.transaction do
    # ✅ Delete related FreeRADIUS records
    RadGroupReply.where(groupname: group_name).destroy_all
    RadGroupCheck.where(groupname: group_name).destroy_all

    # ✅ Delete the HotspotPackage
    @hotspot_package.destroy!
  end

  render json: { message: "Hotspot package deleted successfully" }, status: :ok
rescue => e
  render json: { error: "Failed to delete hotspot package: #{e.message}" }, status: :unprocessable_entity
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
  { attribute: 'Expiration', value: valid_until },
  { attribute: 'Start-Time', value: valid_from },
  { attribute: 'Weekdays', value: weekdays }
]

attributes.each do |attr|
  next if attr[:value].blank? # Skip empty values

  # Use raw SQL to insert the records one by one
  sql = <<-SQL
    INSERT INTO radgroupreply (groupname, attribute, op, value)
    VALUES ('#{name}', '#{attr[:attribute]}', ':=', '#{attr[:value]}')
    ON CONFLICT (groupname, attribute) DO NOTHING
  SQL

  ActiveRecord::Base.connection.execute(sql)
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












# def update_freeradius_policies(package)
#   # group_name = "#{package.name}" # Unique group for each package
#   # now = Time.now.strftime("%Y-%m-%d %H:%M:%S")

#   # ActiveRecord::Base.transaction do
#   #   # Set speed limits in Radgroupreply
#   #   ActiveRecord::Base.connection.execute(<<-SQL)
#   #     INSERT INTO radgroupreply (groupname, radiusattribute, op, value)
#   #     VALUES ('#{group_name}', 'Mikrotik-Rate-Limit', ':=', '#{package.upload_limit}/#{package.download_limit}')
#   #   SQL

#   #   # Handle validity and expiration
#   #   if package.validity.present? && package.validity_period_units.present?
#   #     expiration_time = case package.validity_period_units
#   #     when 'days' then Time.now + (package.validity.to_i * 86400)
#   #     when 'hours' then Time.now + (package.validity.to_i * 3600)
#   #     when 'minutes' then Time.now + (package.validity.to_i * 60)
#   #     end&.strftime("%d %b %Y %H:%M:%S")  # ✅ Correct format for FreeRADIUS

#   #     if expiration_time
#   #       ActiveRecord::Base.connection.execute(<<-SQL)
#   #         INSERT INTO radgroupcheck (groupname, radiusattribute, op, value)
#   #         VALUES ('#{group_name}', 'Expiration', ':=', '#{expiration_time}')
#   #       SQL
#   #     end
#   #   end
#   #   # radiusattribute
#   #   # Handle weekdays restrictions
#   #   # 
#   #   #rename_column :radcheck, :radius_attribute, :radiusattribute

#   #   if package.weekdays.present?
#   #     days_string = package.weekdays.map { |day| day[0..2] }.join(",")

#   #     ActiveRecord::Base.connection.execute(<<-SQL)
#   #       INSERT INTO radgroupcheck (groupname, radiusattribute, op, value)
#   #       VALUES ('#{group_name}', 'Day-Of-Week', ':=', '#{days_string}')
#   #     SQL
#   #   else
#   #     # If no weekdays are set, remove any existing restriction
#   #     ActiveRecord::Base.connection.execute(<<-SQL)
#   #       DELETE FROM radgroupcheck WHERE groupname = '#{group_name}' AND radiusattribute = 'Wk-Day';
#   #     SQL
#   #   end
#   # end
#   # 



#   group_name = package.name # Unique group for each package
# now = Time.current

# ActiveRecord::Base.transaction do
#   # Set speed limits in Radgroupreply
#   RadGroupReply.create!(
#     groupname: group_name,
#     radiusattribute: 'Mikrotik-Rate-Limit',
#     op: ':=',
#     value: "#{package.upload_limit}M/#{package.download_limit}M"
#   )

#   # Handle validity and expiration
#   if package.validity.present? && package.validity_period_units.present?
#       expiration_time = case package.validity_period_units
# when 'days' then Time.current + package.validity.days
# when 'hours' then Time.current + package.validity.hours
# when 'minutes' then Time.current= + package.validity.minutes
# end&.strftime("%d %b %Y %H:%M:%S")


#     if expiration_time
#       RadGroupCheck.create!(
#         groupname: group_name,
#         radiusattribute: 'Expiration',
#         op: ':=',
#         value: expiration_time
#       )
#     end
#   end

#   # Handle weekdays restrictions
#   if package.weekdays.present?
#     days_string = package.weekdays.map { |day| day[0..2] }.join(",")

#     RadGroupCheck.create!(
#       groupname: group_name,
#       radiusattribute: 'Day-Of-Week',
#       op: ':=',
#       value: days_string
#     )
#   else
#     # If no weekdays are set, remove any existing restriction
#     RadGroupCheck.where(groupname: group_name, radiusattribute: 'Wk-Day').destroy_all
#   end
# end

# end







def update_freeradius_policies(package)
  # group_name = "#{package.name}_HotspotPackage" 
group_name = "hotspot_#{package.name.parameterize(separator: '_')}"

  ActiveRecord::Base.transaction do
    # ✅ Update or create speed limits in Radgroupreply
    rad_reply = RadGroupReply.find_or_initialize_by(groupname: group_name, radiusattribute: 'Mikrotik-Rate-Limit')
    rad_reply.update!(op: ':=', value: "#{package.upload_limit}M/#{package.download_limit}M")

    rad_group_check = RadGroupCheck.find_or_initialize_by(groupname: group_name, radiusattribute: 'Simultaneous-Use')
      rad_group_check.update!(op: ':=', value: package.shared_users)

    # ✅ Handle validity and expiration
    # if package.validity.present? && package.validity_period_units.present?
    #   # expiration_time = case package.validity_period_units
    #   #                   when 'days' then Time.current + package.validity.days
    #   #                   when 'hours' then Time.current + package.validity.hours
    #   #                   when 'minutes' then Time.current + package.validity.minutes
    #   #                   end&.strftime("%d %b %Y %H:%M:%S")

    #   # if expiration_time
    #   #   rad_check = RadGroupCheck.find_or_initialize_by(groupname: group_name, radiusattribute: 'Expiration')
    #   #   rad_check.update!(op: ':=', value: expiration_time)
    #   # end
    # else
    #   # ✅ If validity is removed, delete the Expiration record
    #   RadGroupCheck.where(groupname: group_name, radiusattribute: 'Expiration').destroy_all
    # end

    # ✅ Handle weekdays restrictions
    if package.weekdays.present?
      days_string = package.weekdays.map { |day| day[0..2] }.join(",")

      rad_days = RadGroupCheck.find_or_initialize_by(groupname: group_name, radiusattribute: 'Day-Of-Week')
      rad_days.update!(op: ':=', value: days_string)
    else
      # ✅ If no weekdays are set, remove existing restriction
      RadGroupCheck.where(groupname: group_name, radiusattribute: 'Day-Of-Week').destroy_all
    end
  end
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



