class HotspotPackagesController < ApplicationController
  # before_action :set_hotspot_package, only: %i[ show edit update destroy ]

  # GET /hotspot_packages or /hotspot_packages.json

  load_and_authorize_resource :except => [:allow_get_hotspot_packages]


  set_current_tenant_through_filter

  before_action :set_tenant
  before_action :update_last_activity
    before_action :set_time_zone



  # /ip/hotspot/host?as-string=any&as-string-value=any&number=any&value-name=any
    DAY_MAP = {
  "Monday" => "Mo",
  "Tuesday" => "Tu",
  "Wednesday" => "We",
  "Thursday" => "Th",
  "Friday" => "Fr",
  "Saturday" => "Sa",
  "Sunday" => "Su"
}




 def update_last_activity
if current_user
      current_user.update_column(:last_activity_active, Time.now.strftime('%Y-%m-%d %I:%M:%S %p'))
    end
    
  end

  


  def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

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
  



def create
     
  # if HotspotPackage.exists?(name: params[:name])
  #   render json: { error: "Hotspot package already exists" }, status: :unprocessable_entity
  #   return
    
  # end
  

  
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

 update_freeradius_policies(params[:name], 
 params[:shared_users], params[:upload_limit], params[:download_limit],
        params[:weekdays], @hotspot_package.account_id)
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
    update_freeradius_policies(params[:name], params[:shared_users],
     params[:upload_limit], params[:download_limit],
        params[:weekdays], @hotspot_package.account_id)
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
  




def destroy
  @hotspot_package = HotspotPackage.find_by(id: params[:id])

  if @hotspot_package.nil?
    return render json: { error: "Hotspot package not found" }, status: :not_found
  end
ActivtyLog.create(action: 'delete', ip: request.remote_ip,
 description: "Deleted hotspot package #{@hotspot_package.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
  group_name = "hotspot_#{@hotspot_package.account_id}_#{@hotspot_package.name.parameterize(separator: '_')}"


  ActiveRecord::Base.transaction do
    # ✅ Delete related FreeRADIUS records
    RadGroupReply.where(groupname: group_name).destroy_all
    RadGroupCheck.where(groupname: group_name).destroy_all
    # RadGroupCheck.where(groupname: group_name).destroy_all
    # ✅ Delete the HotspotPackage
    @hotspot_package.destroy!
  end

  render json: { message: "Hotspot package deleted successfully" }, status: :ok
rescue => e
  render json: { error: "Failed to delete hotspot package: #{e.message}" }, status: :unprocessable_entity
end


  private
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
  


    




def update_freeradius_policies(package_name, shared_users, 
  upload_limit, download_limit, weekdays, account_id)
  group_name = "hotspot_#{account_id}_#{package_name.parameterize(separator: '_')}"

  ActiveRecord::Base.transaction do
    # Speed limits
    RadGroupReply.find_or_initialize_by(
      groupname: group_name,
      radiusattribute: 'Mikrotik-Rate-Limit'
    ).update!(
      op: ':=',
      value: "#{upload_limit}M/#{download_limit}M"
    )


    RadGroupReply.find_or_initialize_by(
      groupname: group_name,
      radiusattribute: 'Idle-Timeout',

    ).update!(
      op: ':=',
      value: "3600"
    )
    # Simultaneous use
    # RadGroupCheck.find_or_initialize_by(
    #   groupname: group_name,
    #   radiusattribute: 'Simultaneous-Use'
    # ).update!(
    #   op: ':=',
    #   value: shared_users
    # )

    # Login-Time rule
    rad_days = RadGroupCheck.find_or_initialize_by(
      groupname: group_name,
      radiusattribute: 'Login-Time'
    )

    if weekdays.present?
      # Build valid FR format: "Mo0000-2359,Tu0000-2359"
      login_time_value = weekdays.map { |day|
        code = DAY_MAP[day]
        "#{code}0000-2359"
      }.join(",")

      rad_days.update!(
        op: ':=',
        value: login_time_value
      )
    else
      # Allow all days OR disable restriction
      rad_days.update!(
        op: ':=',
        value: 'Al0000-2359'
      )
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
        :location,
        :price,
        :download_limit,
        :upload_limit,
        :valid_from,
        :shared_users,
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



