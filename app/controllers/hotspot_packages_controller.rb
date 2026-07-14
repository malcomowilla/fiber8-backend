class HotspotPackagesController < ApplicationController
  # before_action :set_hotspot_package, only: %i[ show edit update destroy ]

  # GET /hotspot_packages or /hotspot_packages.json

  load_and_authorize_resource :except => [:allow_get_hotspot_packages]


  set_current_tenant_through_filter

  before_action :set_tenant
  before_action :update_last_activity, :except => [:allow_get_hotspot_packages]
    before_action :set_time_zone, :except => [:allow_get_hotspot_packages]



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
    # EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
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

    # @account = Account.find_by(subdomain: host)
    # @hotspot_packages = Rails.cache.fetch("hotspot_packages_index_#{@account.id}", expires_in: 2.seconds) do
    #   HotspotPackage.all
    # end
    @hotspot_packages = HotspotPackage.all
    render json: @hotspot_packages

  end


  def allow_get_hotspot_packages
    # Rails.logger.info "Router IP: #{params.inspect}"

    @hotspot_packages = HotspotPackage.all
    render json: @hotspot_packages
  end
  








  
def create
  if params[:name].blank?
    render json: { error: "package name is required" }, status: :unprocessable_entity
    return
  end

  @hotspot_package = HotspotPackage.new(hotspot_package_params)

  if !@hotspot_package.enable_free_trial && params[:price].blank?
    render json: { error: "price is required" }, status: :unprocessable_entity
    return
  end

  use_radius = router_uses_radius?

  if use_radius
    if @hotspot_package.enable_free_trial
      free_radius_policies_free_trial(params[:name], params[:free_trial_upload_limit],
        params[:free_trial_download_limit],
        params[:weekdays], @hotspot_package.account_id, params[:free_trial_duration_minutes])
    else
      update_freeradius_policies(params[:name],
        params[:shared_users], params[:upload_limit], params[:download_limit],
        params[:weekdays], @hotspot_package.account_id)
    end
  end

  if @hotspot_package.save
    unless use_radius
      if ActiveModel::Type::Boolean.new.cast(params[:sync_to_mikrotik])
        sync_package_natively(@hotspot_package)
      end
    end

    ActivtyLog.create(action: 'create', ip: request.remote_ip,
      description: "Created hotspot package #{@hotspot_package.name}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current)

    render json: @hotspot_package, status: :created
  else
    render json: @hotspot_package.errors, status: :unprocessable_entity
  end
rescue => e
  Rails.logger.error "HotspotPackage create failed: #{e.class} #{e.message}"
  render json: { error: "Failed to create hotspot package: #{e.message}" }, status: :unprocessable_entity
end






def update
  @hotspot_package = set_hotspot_package

  unless @hotspot_package
    render json: { error: 'hotspot package not found' }, status: :not_found
    return
  end

  use_radius = router_uses_radius?

  if use_radius
    if @hotspot_package.enable_free_trial
      free_radius_policies_free_trial(params[:name], params[:free_trial_upload_limit],
        params[:free_trial_download_limit],
        params[:weekdays], @hotspot_package.account_id, params[:free_trial_duration_minutes])
    else
      update_freeradius_policies(params[:name],
        params[:shared_users], params[:upload_limit], params[:download_limit],
        params[:weekdays], @hotspot_package.account_id)
    end
  end

  if @hotspot_package.update(hotspot_package_params)
    unless use_radius
      if ActiveModel::Type::Boolean.new.cast(params[:sync_to_mikrotik])
        sync_package_natively(@hotspot_package)
      end
    end

    ActivtyLog.create(action: 'update', ip: request.remote_ip,
      description: "Updated hotspot package #{@hotspot_package.name}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current)

    render json: @hotspot_package
  else
    render json: @hotspot_package.errors, status: :unprocessable_entity
  end
rescue => e
  Rails.logger.error "HotspotPackage update failed: #{e.class} #{e.message}"
  render json: { error: "Failed to update hotspot package: #{e.message}" }, status: :unprocessable_entity
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

  use_radius = router_uses_radius?

  if use_radius
    group_name = "hotspot_#{@hotspot_package.account_id}_#{@hotspot_package.name.parameterize(separator: '_')}"
    group_name_free_trial = "freetrial_#{@hotspot_package.account_id}_#{@hotspot_package.name.parameterize(separator: '_')}"

    ActiveRecord::Base.transaction do
      RadGroupReply.where(groupname: group_name).destroy_all
      RadGroupReply.where(groupname: group_name_free_trial).destroy_all
      RadGroupCheck.where(groupname: group_name).destroy_all
      RadGroupCheck.where(groupname: group_name_free_trial).destroy_all
      @hotspot_package.destroy!
    end

    render json: { message: "Hotspot package deleted successfully" }, status: :ok
  else
    mikrotik_result = delete_package_natively(@hotspot_package)

    ActiveRecord::Base.transaction do
      @hotspot_package.destroy!
    end

    if mikrotik_result[:success]
      render json: { message: "Hotspot package deleted successfully" }, status: :ok
    else
      Rails.logger.warn "Package deleted locally but MikroTik cleanup failed: #{mikrotik_result[:error]}"
      render json: {
        message: "Hotspot package deleted successfully, but could not remove it from the router",
        mikrotik_error: mikrotik_result[:error]
      }, status: :ok
    end
  end
rescue => e
  Rails.logger.error "HotspotPackage destroy failed: #{e.class} #{e.message}"
  render json: { error: "Failed to delete hotspot package: #{e.message}" }, status: :unprocessable_entity
end

def sync_to_mikrotik
  @hotspot_package = HotspotPackage.find_by(id: params[:id])
  return render json: { error: 'Package not found' }, status: :not_found unless @hotspot_package

  sync_package_natively(@hotspot_package)
  render json: @hotspot_package
rescue => e
  Rails.logger.error "HotspotPackage sync_to_mikrotik failed: #{e.class} #{e.message}"
  render json: { error: "Sync failed: #{e.message}" }, status: :unprocessable_entity
end

def bulk_sync_to_mikrotik
  ids = params[:ids] || []
  packages = HotspotPackage.where(id: ids)
  results = packages.map do |pkg|
    sync_package_natively(pkg)
    { id: pkg.id, sync_status: pkg.sync_status, sync_error: pkg.sync_error }
  end
  render json: results
rescue => e
  Rails.logger.error "HotspotPackage bulk_sync_to_mikrotik failed: #{e.class} #{e.message}"
  render json: { error: "Bulk sync failed: #{e.message}" }, status: :unprocessable_entity
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
  


    




  def free_radius_policies_free_trial(package_name,upload_limit,
  download_limit,
  weekdays, account_id, free_trial_duration_minutes)


  rate_limit_value =  "#{upload_limit}M/#{download_limit}M"
   

  group_name = "freetrial_#{account_id}_#{package_name.parameterize(separator: '_')}"

   ActiveRecord::Base.transaction do
    RadGroupReply.find_or_initialize_by(
      groupname: group_name,
      radiusattribute: 'Mikrotik-Rate-Limit'
    ).update!(
      op: ':=',
      value: rate_limit_value
    )
    

RadGroupReply.find_or_initialize_by(
  groupname: group_name,
  radiusattribute: 'Session-Timeout'
).update!(
  op: ':=',
  value: (free_trial_duration_minutes.to_i * 60).to_s
)






    rad_days = RadGroupCheck.find_or_initialize_by(
      groupname: group_name,
      radiusattribute: 'Login-Time'
    )

    if weekdays.present?
      login_time_value = weekdays.map { |day|
        code = DAY_MAP[day]
        "#{code}0000-2359"
      }.join(",")

      rad_days.update!(
        op: ':=',
        value: login_time_value
      )
    else
      rad_days.update!(
        op: ':=',
        value: 'Al0000-2359'
      )
    end
end

    
  end










  def update_freeradius_policies(
  package_name,
  shared_users,
  upload_limit,
  download_limit,
  weekdays,
  account_id
)

  group_name = "hotspot_#{account_id}_#{package_name.parameterize(separator: '_')}"

  burst_enabled = params[:burst_enabled]

  rate_limit_value =  
    if burst_enabled
      "#{upload_limit}M/#{download_limit}M " \
      "#{params[:burst_limit_upload]}M/#{params[:burst_limit_download]}M " \
      "#{params[:burst_threshold_upload]}M/#{params[:burst_threshold_download]}M " \
      "#{params[:burst_time]}/#{params[:burst_time]}"
    else
      "#{upload_limit}M/#{download_limit}M"
    end

  ActiveRecord::Base.transaction do
    RadGroupReply.find_or_initialize_by(
      groupname: group_name,
      radiusattribute: 'Mikrotik-Rate-Limit'
    ).update!(
      op: ':=',
      value: rate_limit_value
    )

    rad_days = RadGroupCheck.find_or_initialize_by(
      groupname: group_name,
      radiusattribute: 'Login-Time'
    )

    if weekdays.present?
      login_time_value = weekdays.map { |day|
        code = DAY_MAP[day]
        "#{code}0000-2359"
      }.join(",")

      rad_days.update!(
        op: ':=',
        value: login_time_value
      )
    else
      rad_days.update!(
        op: ':=',
        value: 'Al0000-2359'
      )
    end
  end
end







def router_uses_radius?
  setting = RouterSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
  setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
end







def sync_package_natively(pkg)
  nas = NasRouter.find_by(name: pkg.nas_router)
  return pkg.update(sync_status: 'failed', sync_error: 'No router assigned') unless nas

  begin
    session_timeout = validity_in_seconds(pkg)
    rate_limit = "#{pkg.upload_limit}M/#{pkg.download_limit}M"

    response = RestClient::Request.execute(
      method: :put, # put = create-or-update by name in MikroTik REST
      url: "http://#{nas.ip_address}/rest/ip/hotspot/user/profile",
      user: nas.username, password: nas.password,
      payload: {
        name: pkg.name,
        "rate-limit": rate_limit,
        "session-timeout": session_timeout.to_s,
        "shared-users": pkg.shared_users.to_s
      }.to_json,
      headers: { content_type: :json }
    )

    pkg.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)
  rescue => e
    pkg.update(sync_status: 'failed', sync_error: e.message)
  end
end





def validity_in_seconds(pkg)
  case pkg.validity_period_units
  when 'days' then pkg.validity.to_i.days.to_i
  when 'hours' then pkg.validity.to_i.hours.to_i
  when 'minutes' then pkg.validity.to_i.minutes.to_i
  else 0
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
        :tx_rate_limit,
        :nas_router,
        :rx_rate_limit,
        :validity_period_units,
        :download_burst_limit,
        :upload_burst_limit,
        :validity,

         :enable_free_trial,         
      :free_trial_duration_minutes, 
      :free_trial_download_limit,  
      :free_trial_upload_limit,  

        :burst_enabled,
    :burst_limit_download,
    :burst_limit_upload,
    :burst_threshold_download,
    :burst_threshold_upload,
    :burst_time,
     :intended_device_type,    
      :device_icon,      
        weekdays: [],


        
      )
    end
    
end



