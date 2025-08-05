class HotspotVouchersController < ApplicationController
  # before_action :set_hotspot_voucher, only: %i[ show edit update destroy ]

load_and_authorize_resource except: [:login_with_hotspot_voucher, :make_payment]


  set_current_tenant_through_filter

  before_action :set_tenant


  require 'net/http'
  require 'json'
  require 'net/ssh'
  require 'socket'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'message_template'




  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
      ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  # Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end


  # GET /hotspot_vouchers or /hotspot_vouchers.json
  def index
    Rails.logger.info "Router IP: #{params.inspect}"

    @hotspot_vouchers = HotspotVoucher.all
    render json: @hotspot_vouchers
    
# client_ip = request.env['HTTP_X_FORWARDED_FOR'] || request.remote_ip
# Rails.logger.info "Client IP: #{client_ip}"


# local_ip = Socket.ip_address_list.detect do |intf|
#   intf.ipv4_private? && !intf.ipv4_loopback?
# end&.ip_address

# Rails.logger.info "Server IP: #{local_ip || 'Not found'}"

  end




def make_payment

  phone_number = params[:phone_number]
  amount = params[:amount]
  shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.short_code
  # callback_url = "https://df2a-105-163-1-122.ngrok-free.app/customer_mpesa_stk_payments"
  passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.passkey
  consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_key
  consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_secret

  
      # if @customer_wallet_payment.save
      #   render :show, status: :created, location: @customer_wallet_payment
      # else
      #   render json: @customer_wallet_payment.errors, status: :unprocessable_entity
      # end
  
      hotspot_payment = MpesaService.initiate_stk_push(phone_number, amount,
       shortcode,  passkey,
        consumer_key, consumer_secret
      )
  
      if hotspot_payment[:success]
        render json: {
          message: 'Please check your phone to complete the payment',
        }
      else
        render json: { error: 'Failed to initiate payment' }, status: :unprocessable_entity
      end
end


  # GET /hotspot_vouchers/1 or /hotspot_vouchers/1.json
  
def expired_vouchers
  expired_voucher = HotspotVoucher.where(status: 'expired').count
  render json: {expired_voucher: expired_voucher}, status: :ok
end



def active_vouchers
  active_voucher = HotspotVoucher.where(status: 'active').count
  render json: {active_voucher: active_voucher}, status: :ok

end

  # POST /hotspot_vouchers or /hotspot_vouchers.json
  # def create

  #   host = request.headers['X-Subdomain'] 
  #   if host === 'demo'

  # if params[:package].blank?
  #   render json: { error: "hotspot package is required" }, status: :unprocessable_entity
  #   return
  # end

  #     @hotspot_voucher = HotspotVoucher.new(
  #     package: params[:package],
  #     shared_users: params[:shared_users],
  #     phone: params[:phone],
  #     voucher: generate_voucher_code
  #   )
  #   render json: @hotspot_voucher, status: :created


   
  #   else


  #     use_radius = ActsAsTenant.current_tenant.router_setting.use_radius

  #     if params[:package].blank?
  #       render json: { error: "hotspot package is required" }, status: :unprocessable_entity
  #       return
  #     end
  
  #       if use_radius == true
  #     @hotspot_voucher = HotspotVoucher.new(
  #       package: params[:package],
  #       shared_users: params[:shared_users],
  #       phone: params[:phone],
  #       voucher: generate_voucher_code
  #     )
  
  #     user_manager_user_id = get_user_manager_user_id(@hotspot_voucher.voucher)
  #     user_profile_id = get_user_profile_id_from_mikrotik(@hotspot_voucher.voucher)
  # if user_manager_user_id && user_profile_id
  #     # calculate_expiration(package, hotspot_package_created)
  #     @hotspot_voucher.update(
  #       user_manager_user_id: user_manager_user_id,
  #         user_profile_id: user_profile_id,
  #     )
  #     calculate_expiration(params[:package], @hotspot_voucher)
  #       if @hotspot_voucher.save
  
         
  
  
  #         if params[:phone].present?
  #            voucher_expiration = calculate_expiration_send_to_customer(params[:package])
  
  #            if params[:selected_provider] == "SMS leopard"
  #              send_voucher(params[:phone], @hotspot_voucher.voucher,
  #              voucher_expiration
  #              )
               
  #            elsif  params[:selected_provider] == "TextSms"
  #              send_voucher_text_sms(params[:phone], @hotspot_voucher.voucher,
  #              voucher_expiration
  #              )
               
  #            end
  #         # send_voucher(params[:phone], @hotspot_voucher.voucher,
  #         # voucher_expiration
  #         # )
  
  #         end
          
          
  
  
  #         render json: @hotspot_voucher, status: :created
  #       else
  #         render json: @hotspot_voucher.errors, status: :unprocessable_entity 
  #       end
  #     else
  #       Rails.logger.info "Failed to obtain the   user manager user id from mikrotik"
  #       # render json: { error: 'Failed to obtain the   usermanager user id from mikrotik' }, status: :unprocessable_entity
  #     end
  
  #     else
  # puts 'testt123'
  #     end

  #   end

  # end







  def create

    host = request.headers['X-Subdomain'] 
    if host === 'demo'

  if params[:package].blank?
    render json: { error: "hotspot package is required" }, status: :unprocessable_entity
    return
  end

      @hotspot_voucher = HotspotVoucher.new(
      package: params[:package],
      shared_users: params[:shared_users],
      phone: params[:phone],
      voucher: generate_voucher_code
    )
    render json: @hotspot_voucher, status: :created


   
    else

      # use_radius = ActsAsTenant.current_tenant&.router_setting&.use_radius

      if params[:package].blank?
        render json: { error: "hotspot package is required" }, status: :unprocessable_entity
        return
      end
  
      @hotspot_voucher = HotspotVoucher.new(
        package: params[:package],
        shared_users: params[:shared_users],
        phone: params[:phone],
        voucher: generate_voucher_code
      )
    ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created hotspot voucher #{@hotspot_voucher.voucher}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)

      # return render json: { error: "hotspot package required" }, status: :unprocessable_entity unless @hotspot_voucher.package.nil?
      # user_manager_user_id = get_user_manager_user_id(@hotspot_voucher.voucher)
      # user_profile_id = get_user_profile_id_from_mikrotik(@hotspot_voucher.voucher)
      # calculate_expiration(package, hotspot_package_created)
      create_voucher_radcheck(@hotspot_voucher.voucher, @hotspot_voucher.package, @hotspot_voucher.shared_users)
      # @hotspot_voucher.update(
      #   user_manager_user_id: user_manager_user_id,
      #     user_profile_id: user_profile_id,
      # )
      calculate_expiration(params[:package], @hotspot_voucher)
        if @hotspot_voucher.save

  
         
  
  
          if params[:phone].present?
             voucher_expiration = calculate_expiration_send_to_customer(params[:package])
  
             if params[:selected_provider] == "SMS leopard"
               send_voucher(@hotspot_voucher.phone, @hotspot_voucher.voucher,
               voucher_expiration, @hotspot_voucher.shared_users
               )
               
             elsif  params[:selected_provider] == "TextSms"
               send_voucher_text_sms(@hotspot_voucher.phone, @hotspot_voucher.voucher,
               voucher_expiration, @hotspot_voucher.shared_users
               )
               
             end
          # send_voucher(params[:phone], @hotspot_voucher.voucher,
          # voucher_expiration
          # )
          return render json: @hotspot_voucher, status: :created
          end
          
        
  
          render json: @hotspot_voucher, status: :created

          
        else
          render json: @hotspot_voucher.errors, status: :unprocessable_entity 
        end
     
  
      # else
        
      #   create_voucher_radcheck(@hotspot_voucher.voucher, @hotspot_voucher.package, @hotspot_voucher.shared_users)
      
      #   calculate_expiration(params[:package], @hotspot_voucher)
      # end

    end

  end

  def create_voucher_radcheck(hotspot_voucher, package, shared_users)
  
  
# ActiveRecord::Base.connection.execute("
# INSERT INTO radcheck (username, radiusattribute, op, value) 
# SELECT '#{hotspot_voucher}', 'Cleartext-Password', ':=', '#{hotspot_voucher}'
# WHERE NOT EXISTS (
#   SELECT 1 FROM radcheck WHERE username = '#{hotspot_voucher}' AND radiusattribute = 'Cleartext-Password'
# )
# ")

# ActiveRecord::Base.connection.execute("
# INSERT INTO radcheck (username, radiusattribute, op, value) 
# SELECT '#{hotspot_voucher}', 'Simultaneous-Use', ':=', '#{shared_users}'
# WHERE NOT EXISTS (
#   SELECT 1 FROM radcheck WHERE username = '#{hotspot_voucher}' AND radiusattribute = 'Simultaneous-Use'
# )
# ")

# ActiveRecord::Base.connection.execute("
# INSERT INTO radusergroup (username, groupname, priority) 
# VALUES ('#{hotspot_voucher}', '#{package}', 1)
# ")
hotspot_package = "hotspot_#{package.parameterize(separator: '_')}"

# rad_check = RadCheck.find_or_initialize_by(
#       username: pppoe_username,
#       radiusattribute: 'Cleartext-Password'
#     )
#     rad_check.update!(op: ':=', value: pppoe_password)

radcheck = RadCheck.find_or_initialize_by(username: hotspot_voucher, radiusattribute: 
'Cleartext-Password')  

radcheck.update!(op: ':=', value: hotspot_voucher)

radcheck_simultanesous_use = RadCheck.find_or_initialize_by(username: hotspot_voucher, radiusattribute: 
'Simultaneous-Use')
radcheck_simultanesous_use.update!(op: ':=',  value: shared_users.to_s)

rad_user_group = RadUserGroup.find_or_initialize_by(username: hotspot_voucher, groupname: hotspot_package, priority: 1)
rad_user_group.update!(username: hotspot_voucher, groupname: hotspot_package, priority: 1)

rad_reply = RadReply.find_or_initialize_by(username: hotspot_voucher, radiusattribute: 'Idle-Timeout',
 op: ':=', value: '5000')
 
rad_reply.update!(username: hotspot_voucher, radiusattribute: 'Idle-Timeout', op: ':=', value: '5000')
validity_period_units = HotspotPackage.find_by(name: package).validity_period_units
validity = HotspotPackage.find_by(name: package).validity



expiration_time = case validity_period_units
when 'days' then Time.current + validity.days
when 'hours' then Time.current + validity.hours
when 'minutes' then Time.current + validity.minutes
end&.strftime("%d %b %Y %H:%M:%S")

if expiration_time
  rad_check = RadCheck.find_or_initialize_by(username: hotspot_voucher, radiusattribute: 'Expiration')
  rad_check.update!(op: ':=', value: expiration_time)
end
  



end
  


  # PATCH/PUT /hotspot_vouchers/1 or /hotspot_vouchers/1.json
  def update
      @hotspot_voucher = set_hotspot_voucher

      if @hotspot_voucher.update(
        package: params[:package],
        shared_users: params[:shared_users],
        phone: params[:phone],

      )
      ActivtyLog.create(action: 'update', ip: request.remote_ip,
 description: "Updated hotspot voucher #{@hotspot_voucher.voucher}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)

          create_voucher_radcheck(@hotspot_voucher.voucher, @hotspot_voucher.package,
           @hotspot_voucher.shared_users)

        render json: @hotspot_voucher, status: :ok
      else
        render json: @hotspot_voucher.errors, status: :unprocessable_entity 
      
    end
    
  end





def destroy
  @hotspot_voucher = set_hotspot_voucher

  if @hotspot_voucher.nil?
    return render json: { error: "Hotspot voucher not found" }, status: :not_found
  end

  ActiveRecord::Base.transaction do
    # ✅ Delete FreeRADIUS records first
    RadCheck.where(username: @hotspot_voucher.voucher).destroy_all
    RadUserGroup.where(username: @hotspot_voucher.voucher).destroy_all
    RadGroupCheck.where(groupname: @hotspot_voucher.voucher).destroy_all

    # ✅ Delete the HotspotVoucher record
    @hotspot_voucher.destroy!
ActivtyLog.create(action: 'delete', ip: request.remote_ip,
 description: "Deleted hotspot voucher #{@hotspot_voucher.voucher}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
    render json: { message: "Hotspot voucher deleted successfully" }, status: :ok
  end
rescue => e
  render json: { error: "Failed to delete voucher: #{e.message}" }, status: :unprocessable_entity
end


 







def login_with_hotspot_voucher

Rails.loger.info "voucher ip#{params[:ip]}"
  
  return render json: { error: 'voucher is required' }, status: :bad_request unless params[:voucher].present?

  # Get client IP
  client_ip = request.remote_ip



  # Find the voucher in the database
  @hotspot_voucher = HotspotVoucher.find_by(voucher: params[:voucher])
  return render json: { error: 'Invalid voucher' }, status: :not_found unless @hotspot_voucher


      if @hotspot_voucher.expiration.present? && @hotspot_voucher.expiration < Time.current
      return render json: { error: 'Voucher expired' }, status: :forbidden
    end

  active_sessions = get_active_sessions(params[:voucher])

  shared_users = @hotspot_voucher.shared_users.to_i
  
  if active_sessions.any?
    active_voucher_sessions = active_sessions.select { |session| session.include?(params[:voucher]) }
  
    if active_voucher_sessions.count >= shared_users
      return render json: { error: "Voucher is already used by the maximum number of allowed devices (#{shared_users})" }, status: :forbidden
    end
  end
  
 
      nas_routers = NasRouter.all

      nas_routers.each do |nas_router|
        
    router_ip_address = nas_router.ip_address
    router_password = nas_router.password
    router_username = nas_router.username


  command = "/ip hotspot active login user=#{params[:voucher]} password=#{params[:voucher]} ip=#{params[:ip]}"

  begin
    Net::SSH.start(router_ip_address,  router_username, password: router_password, verify_host_key: :never) do |ssh|
      output = ssh.exec!(command)
      if output.include?('failure')
        return render json: { error: "Login failed: #{output}" }, status: :unauthorized
      else
        @hotspot_voucher.update(status: 'used')
        return render json: {
          message: 'Connected successfully',
          device_ip: client_ip,
          response: output
        }, status: :ok
      end
    end
  rescue Net::SSH::AuthenticationFailed
    render json: { error: 'SSH authentication failed' }, status: :unauthorized
  rescue StandardError => e
    render json: { error: "Failed to log in device", message: e.message }, status: :internal_server_error
  end
      end

        
end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_voucher
      @hotspot_voucher = HotspotVoucher.find_by(id: params[:id])
    end






def calculate_expiration(package, hotspot_package_created)
  hotspot_package = HotspotPackage.find_by(name: package)

  return render json: { error: 'Package not found' }, status: :not_found unless hotspot_package
  
  # Calculate expiration
  expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
    case hotspot_package.validity_period_units.downcase
    when 'days'
      Time.current + hotspot_package.validity.days
    when 'hours'
      Time.current + hotspot_package.validity.hours
    when 'minutes'
      Time.current + hotspot_package.validity.minutes
    else
      nil
    end


    

  # elsif hotspot_package.valid_until.present? && hotspot_package.valid_from.present?
  #   hotspot_package.valid_until
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










def calculate_expiration_send_to_customer(package)
  hotspot_package = HotspotPackage.find_by(name: package)

return render json: { error: 'Package not found' }, status: :not_found unless hotspot_package

# Calculate expiration
expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
  case hotspot_package.validity_period_units.downcase
  when 'days'
    Time.current + hotspot_package.validity.days
  when 'hours'
    Time.current + hotspot_package.validity.hours
  when 'minutes'
    Time.current + hotspot_package.validity.minutes
  else
    nil
  end

  # elsif hotspot_package.valid_until.present? && hotspot_package.valid_from.present?
  #   hotspot_package.valid_until


  else
    nil
  end

  
    expiration_time&.strftime("%B %d, %Y at %I:%M %p")
  
end





# selected_provider

    def generate_voucher_code
      loop do
        code = SecureRandom.hex(4).upcase 
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
 request_body["shared-users"] = params[:shared_users] if params[:shared_users].present?
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


        







private



      def send_voucher(phone_number, voucher_code,
        voucher_expiration, shared_users
        )
      # api_key = ActsAsTenant.current_tenant.sms_setting.api_key
      # api_secret = ActsAsTenant.current_tenant.sms_setting.api_secret
      
      api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
    api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
    
              api_key = api_key
              api_secret = api_secret
             
      
      
      sms_template =  ActsAsTenant.current_tenant.sms_template
      send_voucher_template = sms_template&.send_voucher_template
      original_message = sms_template ?  MessageTemplate.interpolate(send_voucher_template,{
        
      voucher_code: voucher_code,
      voucher_expiration: voucher_expiration

      })  :   "Your voucher code: #{voucher_code} for #{shared_users} devices. This code is valid until #{voucher_expiration}.
     Enjoy your browsing"
               
      
      
              sender_id = "SMS_TEST" # Ensure this is a valid sender ID
          
              uri = URI("https://api.smsleopard.com/v1/sms/send")
              params = {
                username: api_key,
                password: api_secret,
                message: original_message,
                destination: phone_number,
                source: sender_id
              }
              uri.query = URI.encode_www_form(params)
          
              response = Net::HTTP.get_response(uri)
              if response.is_a?(Net::HTTPSuccess)
                sms_data = JSON.parse(response.body)
            
                if sms_data['success']
                  sms_recipient = sms_data['recipients'][0]['number']
                  sms_status = sms_data['recipients'][0]['status']
                  
                  puts "Recipient: #{sms_recipient}, Status: #{sms_status}"
            
                  # Save the original message and response details in your database
                  SystemAdminSm.create!(
                    user: sms_recipient,
                    message: original_message,
                    status: sms_status,
                    date:Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
                    system_user: 'system'
                  )
                  
                  # Return a JSON response or whatever is appropriate for your application
                  # render json: { success: true, message: "Message sent successfully", recipient: sms_recipient, status: sms_status }
                else
                  render json: { error: "Failed to send message: #{sms_data['message']}" }
                end
              else
                puts "Failed to send message: #{response.body}"
                # render json: { error: "Failed to send message: #{response.body}" }
              end
            end





           def send_voucher_text_sms(phone_number, voucher_code, voucher_expiration, shared_users
            )
  sms_setting = SmsSetting.find_by(sms_provider: params[:selected_provider])

  if sms_setting.nil?
    render json: { error: "SMS provider not found" }, status: :not_found
    return
  end

  api_key = sms_setting&.api_key
  partnerID = sms_setting&.partnerID 

  sms_template = ActsAsTenant.current_tenant.sms_template
  send_voucher_template = sms_template&.send_voucher_template

  original_message = if sms_template
    MessageTemplate.interpolate(send_voucher_template, { voucher_code: voucher_code })
  else
    "Your voucher code: #{voucher_code} for #{shared_users} devices. This code is valid until #{voucher_expiration}.
     Enjoy your browsing"
  end

  uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
  params = {
    apikey: api_key,
    message: original_message,
    mobile: phone_number,
    partnerID: partnerID,
    shortcode: 'TextSMS'
  }
  uri.query = URI.encode_www_form(params)

  response = Net::HTTP.get_response(uri)

  if response.is_a?(Net::HTTPSuccess)
    sms_data = JSON.parse(response.body)

    if sms_data['responses'] && sms_data['responses'][0]['respose-code'] == 200
      sms_recipient = sms_data['responses'][0]['mobile']
      sms_status = sms_data['responses'][0]['response-description']

      puts "Recipient: #{sms_recipient}, Status: #{sms_status}"

      # Save the message and response details in your database
      SystemAdminSm.create!(
        user: sms_recipient,
        message: original_message,
        status: sms_status,
        date: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
        system_user: 'system'
      )
    else
      # render json: { error: "Failed to send message: #{sms_data['responses'][0]['response-description']}" }
       Rails.logger.info "Failed to send message: #{sms_data['responses'][0]['response-description']}"
    end
  else
    puts "Failed to send message: #{response.body}"
    # render json: { error: "Failed to send message: #{response.body}" }
  end
end


def get_active_sessions(voucher)
  command = "/ip hotspot active print where user=#{voucher}"

  nas_routers = NasRouter.all
nas_routers.each do |nas_router|


  # return [] unless nas_router

  router_ip_address = nas_router.ip_address
  router_password = nas_router.password
  router_username = nas_router.username

  begin
    Net::SSH.start(router_ip_address, router_username, password: router_password, 
    verify_host_key: :never) do |ssh|
      output = ssh.exec!(command)

      if output.include?('failure')
        Rails.logger.error "Getting active sessions failed: #{output}"
        return []
      else
        Rails.logger.info "Response active users from MikroTik: #{output}"
        # active_sessions = output.split("\n").reject(&:empty?)
        active_sessions = output.split("\n").map(&:strip).reject(&:empty?)

        # Remove headers and only keep actual session rows
        active_sessions.reject! { |line| line.start_with?("Flags", "Columns", "#") }
        
        Rails.logger.info "Filtered active sessions: #{active_sessions.inspect}"
        return active_sessions
      end
    end
  rescue Net::SSH::AuthenticationFailed
    Rails.logger.error 'SSH authentication failed'
    return []
  rescue StandardError => e
    Rails.logger.error "Failed to get active sessions: #{e.message}"
    return []
  end
end
  

end



end












