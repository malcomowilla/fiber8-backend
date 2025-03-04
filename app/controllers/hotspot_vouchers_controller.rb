class HotspotVouchersController < ApplicationController
  # before_action :set_hotspot_voucher, only: %i[ show edit update destroy ]




  set_current_tenant_through_filter

  before_action :set_tenant


  require 'net/http'
  require 'json'
  require 'net/ssh'





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


  # GET /hotspot_vouchers or /hotspot_vouchers.json
  def index
    @hotspot_vouchers = HotspotVoucher.all
    render json: @hotspot_vouchers
    
  end

  # GET /hotspot_vouchers/1 or /hotspot_vouchers/1.json
  


  # POST /hotspot_vouchers or /hotspot_vouchers.json
  def create

    use_radius = ActsAsTenant.current_tenant.router_setting.use_radius


      if use_radius == true
    @hotspot_voucher = HotspotVoucher.new(
      package: params[:package],
      voucher: generate_voucher_code
    )

    user_manager_user_id = get_user_manager_user_id(@hotspot_voucher.voucher)
    user_profile_id = get_user_profile_id_from_mikrotik(@hotspot_voucher.voucher)
if user_manager_user_id && user_profile_id
    # calculate_expiration(package, hotspot_package_created)
    @hotspot_voucher.update(
      user_manager_user_id: user_manager_user_id,
        user_profile_id: user_profile_id,
    )
    calculate_expiration(params[:package], @hotspot_voucher)
      if @hotspot_voucher.save
        render json: @hotspot_voucher, status: :created
      else
        render json: @hotspot_voucher.errors, status: :unprocessable_entity 
      end
    else
      Rails.logger.info "Failed to obtain the   usermanager user id from mikrotik"
      # render json: { error: 'Failed to obtain the   usermanager user id from mikrotik' }, status: :unprocessable_entity
    end

    else
puts 'testt123'
    end
  end




  # PATCH/PUT /hotspot_vouchers/1 or /hotspot_vouchers/1.json
  def update
      if @hotspot_voucher.update(
        package: params[:package]
      )
        render json: @hotspot_voucher, status: :ok
      else
        render json: @hotspot_voucher.errors, status: :unprocessable_entity 
      
    end
    
  end



  # DELETE /hotspot_vouchers/1 or /hotspot_vouchers/1.json
  def destroy
    @hotspot_voucher = set_hotspot_voucher
    @hotspot_voucher.destroy!

      head :no_content 
    
  end







  # def login_with_hotspot_voucher
  #   @hotspot_voucher = HotspotVoucher.find_by(voucher: params[:voucher])
  #   if  @hotspot_voucher
  #   router_name = params[:router_name]
  
  #   nas_router = NasRouter.find_by(name: router_name)
    
  #   unless nas_router
  #     return render json: { error: 'Router not found' }, status: 404
  #   end
  
  #   router_ip_address = nas_router.ip_address
  #   router_password = nas_router.password
  #   router_username = nas_router.username
  
  #   uri = URI("http://#{router_ip_address}/rest/ip/hotspot/host")
  #   request = Net::HTTP::Get.new(uri)
  #   request.basic_auth router_username, router_password
  
  #   response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
  
  #   unless response.is_a?(Net::HTTPSuccess)
  #     return render json: { error: "Failed to fetch Mikrotik hosts", status: response.code, message: response.message }, status: 500
  #   end
  
  #   data = JSON.parse(response.body)
  #   failed_hosts = []
  #   successful_hosts = []
  
  #   data.each do |host|
  #     host_ip = host['address']
  #     host_mac = host['mac-address']
  
  #     command = "/ip hotspot active login user=#{params[:voucher]} ip=#{host_ip}"
      
  #     begin
  #       Net::SSH.start(router_ip_address, router_username, password: router_password, verify_host_key: :never) do |ssh|
  #         output = ssh.exec!(command)
  #         successful_hosts << { ip: host_ip, mac: host_mac, response: output }
  #       end
  #     rescue StandardError => e
  #       failed_hosts << { ip: host_ip, mac: host_mac, error: e.message }
  #     end
  #   end
  
  #   render json: {
  #     message: 'Mikrotik host data processed successfully',
  #     successful_hosts: successful_hosts,
  #     failed_hosts: failed_hosts
  #   }, status: :ok


  # else
  #   render json: { error: 'invalid voucher' }, status: :not_found
  # end
  # end
  

  def login_with_hotspot_voucher
    return render json: { error: 'Voucher and router name are required' }, 
    status: :bad_request unless params[:voucher].present? 
  
    @hotspot_voucher = HotspotVoucher.find_by(voucher: params[:voucher])
    return render json: { error: 'Invalid voucher' }, status: :not_found unless @hotspot_voucher
  
    # Check if the voucher is expired (Assuming there's an `expires_at` column)
    if @hotspot_voucher.expiration.present? && @hotspot_voucher.expiration < Time.current
      return render json: { error: 'Voucher expired' }, status: :forbidden
    end
    
  
    nas_router = NasRouter.find_by(name: params[:router_name]) || NasRouter.find_by(name: ActsAsTenant.current_tenant.router_setting)
    return render json: { error: 'Router not found' }, status: :not_found unless nas_router
  
    router_ip_address = nas_router.ip_address
    router_password = nas_router.password
    router_username = nas_router.username
  
    uri = URI("http://#{router_ip_address}/rest/ip/hotspot/host")
    request = Net::HTTP::Get.new(uri)
    request.basic_auth router_username, router_password
  
    begin
      response = Net::HTTP.start(uri.hostname, uri.port, read_timeout: 10, open_timeout: 5) { |http| http.request(request) }
      return render json: { error: "Failed to fetch MikroTik hosts", status: response.code, message: response.message }, status: :internal_server_error unless response.is_a?(Net::HTTPSuccess)
    rescue StandardError => e
      return render json: { error: "Failed to connect to router", message: e.message }, status: :internal_server_error
    end
  
    data = JSON.parse(response.body)
    failed_hosts = []
    successful_hosts = []
  
    data.each do |host|
      host_ip = host['address']
      host_mac = host['mac-address']
      command = "/ip hotspot active login user=#{params[:voucher]} ip=#{host_ip}"
  
      begin
        Net::SSH.start(router_ip_address, router_username, password: router_password, verify_host_key: :never) do |ssh|
          output = ssh.exec!(command)
          if output.include?('failure')
            failed_hosts << { ip: host_ip, mac: host_mac, error: "Login failed: #{output}" }
          else
            successful_hosts << { ip: host_ip, mac: host_mac, response: output }
          end
        end
      rescue Net::SSH::AuthenticationFailed
        return render json: { error: 'SSH authentication failed' }, status: :unauthorized
      rescue StandardError => e
        failed_hosts << { ip: host_ip, mac: host_mac, error: e.message }
      end
    end
  
    if successful_hosts.any?
      return render json: {
        message: 'Connected successfully',
        successful_hosts: successful_hosts,
        failed_hosts: failed_hosts
      }, status: :ok
    else
      return render json: {
        error: 'Failed to connect any devices',
        failed_hosts: failed_hosts
      }, status: :internal_server_error
    end
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_voucher
      @hotspot_voucher = HotspotVoucher.find_by(id: params[:id])
    end


    # def calculate_expiration(package)
    #   hotspot_package = HotspotPackage.find_by(name: package)

      

    #   return render json: { error: 'Package not found' }, status: :not_found unless hotspot_package
    
    #   expiration_time = case hotspot_package.validity_period_units.downcase
    #   when 'days'
    #     Time.current + hotspot_package.validity.days
    #   when 'hours'
    #     Time.current + hotspot_package.validity.hours
    #   when 'minutes'
    #     Time.current + hotspot_package.validity.minutes

    #   when hotspot_package.valid_until 
    #  Time.current + hotspot_package.validity.until

    #   when  hotspot_package.valid_from
    #     Time.current + hotspot_package.validity.from
    #   else
    #     nil
    #   end

    #   expiration_time&.strftime("%B %d, %Y at %I:%M %p")
    # end
    


#     def calculate_expiration(package)
#   hotspot_package = HotspotPackage.find_by(name: package)

#   return render json: { error: 'Package not found' }, status: :not_found unless hotspot_package

#   expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
#     # Use valid_from as the start time if available, otherwise use current time
#     start_time = hotspot_package.valid_from || Time.current

#     case hotspot_package.validity_period_units.downcase
#     when 'days'
#       start_time + hotspot_package.validity.days
#     when 'hours'
#       start_time + hotspot_package.validity.hours
#     when 'minutes'
#       start_time + hotspot_package.validity.minutes
#     else
#       nil
#     end
#   elsif hotspot_package.valid_until.present?
#     # If no validity, just use the valid_until time
#     hotspot_package.valid_until
#   else
#     nil
#   end

#   expiration_time&.strftime("%B %d, %Y at %I:%M %p")
# end
# 





def calculate_expiration(package, hotspot_package_created)
  hotspot_package = HotspotPackage.find_by(name: package)

  return render json: { error: 'Package not found' }, status: :not_found unless hotspot_package

  # Calculate expiration
  expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
    start_time = hotspot_package.valid_from || Time.current

    case hotspot_package.validity_period_units.downcase
    when 'days'
      start_time + hotspot_package.validity.days
    when 'hours'
      start_time + hotspot_package.validity.hours
    when 'minutes'
      start_time + hotspot_package.validity.minutes
    else
      nil
    end
  elsif hotspot_package.valid_until.present? && hotspot_package.valid_from.present?
    hotspot_package.valid_until
  else
    nil
  end

  # Update status only if expiration is present
  if expiration_time.present?
    status = expiration_time > Time.current ? "active" : "expired"
    hotspot_package_created.update(status: status,  expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),)
  else
    status = "unknown" # Handle cases with no expiration logic
  end

  # Return both expiration and status
  {
    expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),
    status: status
  }
end



    def generate_voucher_code
      loop do
        code = "HS-" + SecureRandom.hex(4).upcase # Example: HS-A1B2C3D4
        break code unless HotspotVoucher.exists?(voucher: code)
      end
    end
    # Only allow a list of trusted parameters through.
    def hotspot_voucher_params
      params.permit(:voucher, :status, :expiration, :speed_limit, :phone,
      :package)
    end










def get_user_manager_user_id(hotspot_voucher)
  router_name = params[:router_name]
  nas_router = NasRouter.find_by(name: router_name)
  if nas_router
    router_ip_address = nas_router.ip_address
      router_password = nas_router.password
     router_username = nas_router.username
  
  else
  
    render json: { error: 'NAS router not found' }, status: :not_found
    return
  end



  request_body = {
   
    
    "name": "#{hotspot_voucher}",
   
}

uri = URI("http://#{router_ip_address}/rest/user-manager/user/add")
request = Net::HTTP::Post.new(uri)
request.basic_auth router_username, router_password
request['Content-Type'] = 'application/json'
request.body = request_body.to_json

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

if response.is_a?(Net::HTTPSuccess)
  data = JSON.parse(response.body)
        return data['ret']

else
  puts "Failed to fetch user manager user from mikrotik  : #{response.code} - #{response.message}"
end

  
end





def get_user_profile_id_from_mikrotik(hotspot_voucher)
  router_name = params[:router_name]
  nas_router = NasRouter.find_by(name: router_name)
  if nas_router
    router_ip_address = nas_router.ip_address
      router_password = nas_router.password
     router_username = nas_router.username
  
  else
  
    render json: { error: 'NAS router not found' }, status: :not_found
    return
  end


  request_body = {
   
    
  # "user": "#{hotspot_voucher.voucher}",
  
      "user": "#{hotspot_voucher}",
    "profile": "#{params[:package]}",
 
}
Rails.logger.info "Request body: #{request_body}"

uri = URI("http://#{router_ip_address}/rest/user-manager/user-profile/add")
request = Net::HTTP::Post.new(uri)
request.basic_auth router_username, router_password
request['Content-Type'] = 'application/json'
request.body = request_body.to_json

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
http.request(request)
end

if response.is_a?(Net::HTTPSuccess)
data = JSON.parse(response.body)
      return data['ret']

else
puts "Failed to fetch user manager user profile id from mikrotik : #{response.code} - #{response.message}"
end



    end


        








    # {{b aseUrl}}/user-manager/user-profile/add

    # {
    #   "copy-from": "any",
    #   "profile": "any",
    #   "user": "any",
    #   ".proplist": "any",
    #   ".query": "array"
    # }








    # /user-manager/user/add
#     {
#   "attributes": "any",
#   "caller-id": "any",
#   "comment": "any",
#   "copy-from": "any",
#   "disabled": "any",
#   "group": "any",
#   "name": "any",
#   "otp-secret": "any",
#   "password": "any",
#   "shared-users": "any",
#   ".proplist": "any",
#   ".query": "array"
# }
# 
#
end
