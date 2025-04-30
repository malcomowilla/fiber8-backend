class SubscriptionsController < ApplicationController
  # before_action :set_subscription, only: %i[ show edit update destroy ]

  # GET /subscriptions or /subscriptions.json
  require 'net/ssh'

set_current_tenant_through_filter

before_action :set_current_tenant

load_and_authorize_resource

  
    
def set_current_tenant

  host = request.headers['X-Subdomain']
  @account = Account.find_by(subdomain: host)
   @current_account=ActsAsTenant.current_tenant 
  EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])

  # set_current_tenant(@account)
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Invalid tenant' }, status: :not_found

  
end




def last_seen
  subscriptions = Subscription.all

  data = subscriptions.map do |subscription|
    radacct_records = RadAcct.where(username: subscription.ppoe_username).order(acctupdatetime: :desc)

    radacct = radacct_records.find { |r| r.acctstoptime.nil? } || radacct_records.first

    Rails.logger.info "radacct: #{radacct.inspect}"

    if radacct
      if radacct.acctstoptime.nil?
        {
          id: subscription.id,
          ppoe_username: subscription.ppoe_username,
          status: subscription.status == 'blocked' ? 'blocked' : 'online',
          last_seen: radacct.acctupdatetime.strftime("%B %d, %Y at %I:%M %p"),
          mac_adress: radacct.callingstationid
        }
      else
        {
          id: subscription.id,
          ppoe_username: subscription.ppoe_username,
          status: "offline",
          last_seen: radacct.acctstoptime.strftime("%B %d, %Y at %I:%M %p"),
          mac_adress: radacct.callingstationid
        }
      end
    else
      {
        id: subscription.id,
        ppoe_username: subscription.ppoe_username,
        status: "never connected",
        last_seen: nil
      }
    end
  end

  render json: data
end


def block_service
  begin
    router_setting = ActsAsTenant.current_tenant&.router_setting&.router_name
router = NasRouter.find_by(name: router_setting)

return unless router
  ip_address =  params[:subscription][:ip_address],
  ppoe_username = params[:subscription][:ppoe_username],

subscription = Subscription.find_by(ppoe_username: ppoe_username)
router_ip = router.ip_address
router_username = router.username
router_password = router.password 
    # SSH into MikroTik router
    Net::SSH.start(router_ip, router_username , password: router_password) do |ssh|
      # Add the user's IP address to the MikroTik Address List
      ssh.exec!("ip firewall address-list add list=aitechs_blocked_list address=#{params[:subscription][:ip_address]} comment=#{params[:subscription][:ppoe_username]}")

      puts "Blocked #{ppoe_username} (#{ip_address}) on MikroTik."
render json: { message: "Blocked #{ppoe_username} (#{ip_address}) on MikroTik." }
      # Update subscription status in DB
      subscription.update!(status: 'blocked')
    end
  rescue => e
    puts "Error blocking #{subscription.username}: #{e.message}"
  end

end





def parse_uptime_to_seconds(uptime)
  total_seconds = 0
  uptime.scan(/(\d+d)?(\d+h)?(\d+m)?(\d+s)?/).each do |d, h, m, s|
    total_seconds += d.to_i * 86400 if d
    total_seconds += h.to_i * 3600 if h
    total_seconds += m.to_i * 60 if m
    total_seconds += s.to_i if s
  end
  total_seconds
end

def fetch_pppoe_stats
  router_setting = ActsAsTenant.current_tenant&.router_setting&.router_name
  router = NasRouter.find_by(name: router_setting)

  return [] unless router

  router_ip = router.ip_address
  router_username = router.username
  router_password = router.password 

  stats = []

  Net::SSH.start(router_ip, router_username, password: router_password, verify_host_key: :never) do |ssh|
    output = ssh.exec!('/ppp active print detail')
    Rails.logger.info "PPPoE stats: #{output}"

    output.scan(/name="(.+?)".*?address=(.+?) uptime=(.+?) /m).each do |match|
      username = match[0]
      address = match[1]
      uptime_raw = match[2]

      interface_name = "<pppoe-#{username}>"
      ppoe_username = Subscription.find_by(ppoe_username: username)
      # Rails.logger.info 'ppoe_username', ppoe_username
      package = ppoe_username&.package
      mbps_package = Package.find_by(name: package)
      download_limit = mbps_package&.download_limit
      upload_limit = mbps_package&.upload_limit
      traffic_output = ssh.exec!("/interface monitor-traffic interface=#{interface_name} once")
      Rails.logger.info "Traffic stats for #{username}: #{traffic_output}"

      rx_speed = extract_speed_direct(traffic_output[/rx-bits-per-second:\s+(\S+)/, 1])
      tx_speed = extract_speed_direct(traffic_output[/tx-bits-per-second:\s+(\S+)/, 1])

      stats << {
        username: username,
        address: address,
        uptime: uptime_raw,
        download_speed: rx_speed,
        upload_speed: tx_speed,
        package: "#{download_limit} Mbps"
      }
    end
  end

  stats

rescue => e
  Rails.logger.error "Failed to fetch PPPoE stats: #{e.message}"
  []
end

# 🛠 This is the simple parser that accepts whatever Mikrotik gave
def extract_speed_direct(raw_value)
  return "0 bps" if raw_value.blank?

  # Mikrotik gives with unit already, just format spacing better
  if raw_value =~ /^(\d+(\.\d+)?)([a-zA-Z]+)$/
    number = Regexp.last_match(1)
    unit = Regexp.last_match(3)
    "#{number} #{unit}"
  else
    raw_value
  end
end

def pppoe_stats
  stats = fetch_pppoe_stats
  render json: stats
end





  def index
    @subscriptions = Subscription.all
    render json: @subscriptions
  end





  def get_ips
    # Step 1: Get the network details
    network = IpNetwork.find_by(title: params[:network_name])
  
    if network.nil?
      render json: { error: "Network not found" }, status: 404 and return
    end
  
    # Step 2: Parse the network and generate the range
    cidr = "#{network.network}/#{network.subnet_mask}"
    network_range = IPAddr.new(cidr).to_range.to_a
  
    # Step 3: Filter out reserved IPs
    reserved_ips = [
      network_range.first,  # Network address (.0)
      network_range.last,   # Broadcast address (.255)
      IPAddr.new(network_range.first.to_i + 1, Socket::AF_INET)  # Typically .1 (gateway)
    ]
  
    available_ips = network_range - reserved_ips
  
    # Step 4: Exclude already used IPs
    used_ips = Subscription.pluck(:ip_address).compact.map { |ip| IPAddr.new(ip) }
    available_ips -= used_ips
  
    # Step 5: Select a small, unique set of IPs (e.g., 5 IPs)
    limited_ips = available_ips.sample(5) # You can change 5 to whatever small number you want
  
    if limited_ips.empty?
      render json: { error: "No available IPs in the network" }, status: 404 and return
    end
  
    # Step 6: Return the selected IPs
    render json: limited_ips.map(&:to_s)
  end
  

  # POST /subscriptions or /subscriptions.json
  def create


    if params[:subscription][:ppoe_username].blank? || params[:subscription][:ppoe_password].blank?
      render json: { error: "Username and password are required" }, status: :unprocessable_entity
      return
    end
  
    # Check uniqueness manually
    if Subscription.exists?(ppoe_username: params[:subscription][:ppoe_username])
      render json: { error: "Username already taken" }, status: :unprocessable_entity
      return
    end
    use_autogenerated_number_as_ppoe_password = ActsAsTenant.current_tenant.subscriber_setting.use_autogenerated_number_as_ppoe_password
    use_autogenerated_number_as_ppoe_username = ActsAsTenant.current_tenant.subscriber_setting.use_autogenerated_number_as_ppoe_username
   

    if !use_autogenerated_number_as_ppoe_password && !use_autogenerated_number_as_ppoe_username
      if Subscription.exists?(ppoe_username: params[:subscription][:ppoe_username])
        render json: { error: "ppoe username already exists" }, status: :unprocessable_entity
        return
        
      end
    end
    
    @subscription = Subscription.create(
      
    # params[:subscription][:name],
    package: params[:subscription][:package_name],
    phone_number: params[:subscription][:phone_number],
  status:  params[:subscription][:status],
  ip_address: params[:subscription][:ip_address],
  ppoe_username:  params[:subscription][:ppoe_username],
  ppoe_password:  params[:subscription][:ppoe_password],
  type:  params[:subscription][:type],
  network_name: params[:subscription][:network_name],
  # mac_address: params[:subscription][:mac_address],
  validity_period_units: params[:subscription][:validity_period_units],
  validity:  params[:subscription][:validity]

    )

    create_pppoe_credentials_radius(params[:subscription][:ppoe_password], 
    params[:subscription][:ppoe_username], params[:subscription][:package_name],  params[:subscription][:ip_address])
   
    
    calculate_expiration(@subscription)
    limit_bandwidth(params[:subscription][:ip_address], params[:subscription][:package_name], params[:subscription][:ppoe_username])
      if @subscription.save
         render json: @subscription, status: :created


      else
     render json: @subscription.errors, status: :unprocessable_entity 
      end
    

  end

  
  def destroy
    @subscription = set_subscription
  
    if @subscription.nil?
      return render json: { error: "Subscription not found" }, status: :not_found
    end
  
    ActiveRecord::Base.transaction do
      # ✅ Delete FreeRADIUS records first
      RadCheck.where(username: @subscription.ppoe_username).destroy_all
      RadGroupCheck.where(groupname: @subscription.ppoe_username).destroy_all
      RadGroupCheck.where(groupname: @subscription.ppoe_password).destroy_all

      RadUserGroup.where(username: @subscription.ppoe_username).destroy_all
      RadUserGroup.where(username: @subscription.ppoe_password).destroy_all
 
  
  #     # ✅ Delete the HotspotVoucher record
      @subscription.destroy!
  
      render json: { message: "subscription deleted successfully" }, status: :ok
    end
  rescue => e
    render json: { error: "Failed to delete subscription: #{e.message}" }, status: :unprocessable_entity
  end


  # def update
  #   @subscription = set_subscription
  #   if params[:subscription][:ppoe_username].blank? || params[:subscription][:ppoe_password].blank?
  #     render json: { error: "Username and password are required" }, status: :unprocessable_entity
  #     return
  #   end
  
  #   # Check uniqueness manually
  #   if Subscription.where(ppoe_username: params[:subscription][:ppoe_username])
  #     .where.not(id: @subscription.id)
  #     .exists?
  #     render json: { error: "Username already taken" }, status: :unprocessable_entity
  #     return
  #   end
  #   if @subscription.update(subscription_params)
  #     calculate_expiration(@subscription)
  #     create_pppoe_credentials_radius(params[:subscription][:ppoe_password], 
  #     params[:subscription][:ppoe_username], params[:subscription][:package_name],  params[:subscription][:ip_address])
     
  #     render json: @subscription, status: :ok
  #   else
  #     render json: @subscription.errors, status: :unprocessable_entity
  #   end
  # end
  def update
    @subscription = set_subscription
    if params[:subscription][:ppoe_username].blank? || params[:subscription][:ppoe_password].blank?
      render json: { error: "Username and password are required" }, status: :unprocessable_entity
      return
    end
  
    # Check uniqueness manually
    if Subscription.where(ppoe_username: params[:subscription][:ppoe_username])
      .where.not(id: @subscription.id)
      .exists?
      render json: { error: "Username already taken" }, status: :unprocessable_entity
      return
    end







    
  
    old_ip = @subscription.ip_address # store the old IP
  
    # Update the subscription record
    if @subscription.update(subscription_params)
      # If IP address has changed, update bandwidth limits
      if old_ip != @subscription.ip_address
        # Remove old bandwidth limit (if any) for the old IP
        remove_bandwidth_limit(old_ip)
        render json: @subscription, status: :ok

        
        # Limit bandwidth for the new IP
        limit_bandwidth(@subscription.ip_address, @subscription.package, @subscription.ppoe_username)
      end
  
      # calculate_expiration(@subscription)
       calculate_expiration_update(@subscription)
      create_pppoe_credentials_radius(params[:subscription][:ppoe_password], 
      params[:subscription][:ppoe_username], params[:subscription][:package_name],  params[:subscription][:ip_address])
      remove_pppoe_connection(params[:subscription][:ppoe_username])
      render json: @subscription, status: :ok
    else
      render json: @subscription.errors, status: :unprocessable_entity
    end
  end
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find_by(id: params[:id])
    end

    def remove_pppoe_connection(ppoe_username)
      begin
        router_setting = ActsAsTenant.current_tenant&.router_setting&.router_name
        router = NasRouter.find_by(name: router_setting)
      
        return unless router
        
        router_ip = router.ip_address
        router_username = router.username
        router_password = router.password 
        
        # Connect via SSH to MikroTik
        Net::SSH.start(router_ip, router_username, password: router_password, verify_host_key: :never) do |ssh|
          # Correct command to remove active PPPoE session based on pppoe_username
          command = "/ppp active remove [find name=#{ppoe_username}]"
          
          # Execute the command
          ssh.exec!(command)
        end
      rescue StandardError => e
        Rails.logger.error "Error removing PPPoE connection for username #{ppoe_username}: #{e.message}"
      end
    end
    


    def create_pppoe_credentials_radius(pppoe_password, pppoe_username, package, pppoe_ip)

      pppoe_package = "pppoe_#{package.parameterize(separator: '_')}"

  use_autogenerated_number_as_ppoe_password = ActsAsTenant.current_tenant.subscriber_setting.use_autogenerated_number_as_ppoe_password
  use_autogenerated_number_as_ppoe_username = ActsAsTenant.current_tenant.subscriber_setting.use_autogenerated_number_as_ppoe_username
 
  
  

      # Create or update RadCheck (password)
      rad_check = RadCheck.find_or_initialize_by(username: pppoe_username, radiusattribute: 'Cleartext-Password')
      rad_check.assign_attributes(op: ':=', value: pppoe_password)
      rad_check.save!

      rad_reply = RadReply.find_or_initialize_by(username: pppoe_username, radiusattribute: 'Framed-IP-Address')
      rad_reply.assign_attributes(op: '=', value: pppoe_ip)
      rad_reply.save!
    
      # Create or update RadUserGroup (package)
      use_autogenerated_number_as_ppoe_username && user_group = RadUserGroup.find_or_initialize_by(username: pppoe_username, groupname: pppoe_package)
      use_autogenerated_number_as_ppoe_password && user_group = RadUserGroup.find_or_initialize_by(username: pppoe_password, groupname: pppoe_package)


      if !use_autogenerated_number_as_ppoe_password && !use_autogenerated_number_as_ppoe_username
        user_group = RadUserGroup.find_or_initialize_by(username: pppoe_username, groupname: pppoe_package)
      end

      user_group.assign_attributes(groupname: pppoe_package, priority: 1)
      user_group.save!
    
      # Get package validity
      pkg = Package.find_by(name: package)
      validity_period_units = pkg&.validity_period_units
      validity = pkg&.validity
    
      expiration_time = case validity_period_units
                        when 'days' then Time.current + validity.days
                        when 'hours' then Time.current + validity.hours
                        when 'minutes' then Time.current + validity.minutes
                        end&.strftime("%d %b %Y %H:%M:%S")
    
      # Create or update Expiration in RadGroupCheck
      if expiration_time


        use_autogenerated_number_as_ppoe_username && user_group = RadUserGroup.find_or_initialize_by(username: pppoe_username, groupname: pppoe_package)
        use_autogenerated_number_as_ppoe_password && user_group = RadUserGroup.find_or_initialize_by(username: pppoe_password, groupname: pppoe_package)
  

        use_autogenerated_number_as_ppoe_username && user_group = RadUserGroup.find_or_initialize_by(username: pppoe_username, groupname: pppoe_package)
        use_autogenerated_number_as_ppoe_password && user_group = RadUserGroup.find_or_initialize_by(username: pppoe_password, groupname: pppoe_package)
  
  

if use_autogenerated_number_as_ppoe_username
  expiration_check = RadGroupCheck.find_or_initialize_by(groupname: pppoe_username, radiusattribute: 'Expiration')
  expiration_check.assign_attributes(op: ':=', value: expiration_time)
  expiration_check.save!
end



if use_autogenerated_number_as_ppoe_password
  expiration_check = RadGroupCheck.find_or_initialize_by(groupname: pppoe_password, radiusattribute: 'Expiration')
  expiration_check.assign_attributes(op: ':=', value: expiration_time)
  expiration_check.save!
end
  
        if !use_autogenerated_number_as_ppoe_password && !use_autogenerated_number_as_ppoe_username
          expiration_check = RadGroupCheck.find_or_initialize_by(groupname: pppoe_username, radiusattribute: 'Expiration')
          expiration_check.assign_attributes(op: ':=', value: expiration_time)
          expiration_check.save!
        end



       
      end
      
      
      
      end




    
    def calculate_expiration(subscription)
      return nil unless subscription.validity.present? && subscription.validity_period_units.present?
    
      validity = subscription.validity.to_i
    
      # Calculate expiration time
      expiration_time = case subscription.validity_period_units.downcase
                        when 'days'
                          Time.current + validity.days
                        when 'hours'
                          Time.current + validity.hours
                        when 'minutes'
                          Time.current + validity.minutes
                        else
                          nil
                        end
    
      # If expiration was calculated, update the subscription
      if expiration_time
        subscription.update(expiry: expiration_time)
        formatted_expiry = expiration_time.strftime("%B %d, %Y at %I:%M %p")
      else
        formatted_expiry = "unknown"
      end
    
      # Return formatted expiry
      {
        expiry: formatted_expiry
      }
    end
    

    def calculate_expiration_update(subscription)
      return nil unless subscription.validity.present? && subscription.validity_period_units.present?
    
      validity = subscription.validity.to_i
    
      # Calculate new expiration time
      expiration_time = case subscription.validity_period_units.downcase
                        when 'days'
                          Time.current + validity.days
                        when 'hours'
                          Time.current + validity.hours
                        when 'minutes'
                          Time.current + validity.minutes
                        else
                          nil
                        end
    
      if expiration_time
        old_expiry = subscription.expiry
    
        # Update subscription expiry
        subscription.update(expiry: expiration_time)
    
        # If expiry was changed, remove IP from address list in MikroTik
        if old_expiry != expiration_time
          begin
            router_setting = ActsAsTenant.current_tenant&.router_setting&.router_name
            router = NasRouter.find_by(name: router_setting)
    
            if router
              Net::SSH.start(router.ip_address, router.username, password: router.password) do |ssh|
                ssh.exec!("ip firewall address-list remove [find list=aitechs_blocked_list address=#{subscription.ip_address}]")
                subscription.update!(status: 'online')
                puts "Removed #{subscription.ip_address} from aitechs_blocked_list"
              end
            end
          rescue => e
            puts "Error unblocking IP: #{e.message}"
          end
        end
    
        formatted_expiry = expiration_time.strftime("%B %d, %Y at %I:%M %p")
      else
        formatted_expiry = "unknown"
      end
    
      {
        expiry: formatted_expiry
      }
    end
    



    def limit_bandwidth(ip_address, package, ppoe_username)
      
      package = Package.find_by(name: package)
      download_limit = package&.download_limit
      upload_limit = package&.upload_limit
      begin
        # MikroTik SSH connection details
        router_setting = ActsAsTenant.current_tenant&.router_setting&.router_name
        router = NasRouter.find_by(name: router_setting)
    
        return unless router
    
        router_ip = router.ip_address
        router_username = router.username
        router_password = router.password 
    
        # Connect via SSH to MikroTik
        Net::SSH.start(router_ip, router_username, password: router_password, verify_host_key: :never) do |ssh|
          # Command to limit the bandwidth (4M/4M)
          command = "/queue simple add name=aitechs_limit_#{ppoe_username} target=#{ip_address} max-limit=#{download_limit}M/#{upload_limit}M"
          
          # Execute the command
          ssh.exec!(command)
        end
      rescue StandardError => e
        Rails.logger.error "Error limiting bandwidth for IP #{ip_address}: #{e.message}"
      end
    end




def remove_bandwidth_limit(ip_address)
  # Assuming a MikroTik command to remove the limit is something like this:
  begin
    router_setting = ActsAsTenant.current_tenant&.router_setting&.router_name
    router = NasRouter.find_by(name: router_setting)
  
    return unless router
    
    router_ip = router.ip_address
    router_username = router.username
    router_password = router.password 
    
    # Connect via SSH to MikroTik
    Net::SSH.start(router_ip, router_username, password: router_password, verify_host_key: :never) do |ssh|
      # Command to remove the bandwidth limit
      command = "/queue simple remove [find target=#{ip_address}]"
      
      # Execute the command
      ssh.exec!(command)
    end
  rescue StandardError => e
    Rails.logger.error "Error removing bandwidth limit for IP #{ip_address}: #{e.message}"
  end
end



# "burst-limit": "any",
#   "burst-threshold": "any",
#   "burst-time": "any",
    # Only allow a list of trusted parameters through.
    def subscription_params
      params.require(:subscription).permit(:name, :phone_number, :package, :status, 
      :last_subscribed, :expiry, :ip_address,
       :ppoe_username, :ppoe_password, :type, :network_name, :mac_address, :validity_period_units, :validity)
    end

   

end
