# class HotspotVouchersController < ApplicationController
#   include BroadcastsHotspotPayments

# load_and_authorize_resource except: [:login_with_hotspot_voucher,
#  :make_payment, :check_payment_status, :payment_and_conected_status,
#  :login_with_receipt_number, :calculate_expiration_login_with_voucher,
#  :create_voucher_radcheck, :receipt_number_status, :stk_push_status, :payment_reference_status

# ]
#   # skip_before_action :set_tenant, only: [:check_payment_status]


#   set_current_tenant_through_filter

#   before_action :set_tenant, except: [:check_payment_status,
#    :transaction_status_result]
#   before_action :set_time_zone


#   #  before_action :whitelist_mpesa_ips, only: [:check_payment_status]




# def whitelist_mpesa_ips
#     allowed_ips = [
#       '196.201.214.200',
#       '196.201.214.206',
#       '196.201.213.114',
#       '196.201.214.207',
#       '196.201.214.208',
#       '196.201.213.44',
#       '196.201.212.127',
#       '196.201.212.138',
#       '196.201.212.129',
#       '196.201.212.136',
#       '196.201.212.74',
#       '196.201.212.69'
#     ]

#     unless allowed_ips.include?(request.remote_ip)
#       Rails.logger.info "Not Authorized Safaricom IP: #{request.remote_ip}"
#       render json: { error: 'Not Authorized Safaricom IP' }, status: :not_found
#     end
#   end

#   require 'net/http'
#   require 'json'
#   require 'net/ssh'
#   require 'socket'
# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
# require 'message_template'




#   def set_tenant
#     host = request.headers['X-Subdomain']
#     @account = Account.find_by(subdomain: host)
#       ActsAsTenant.current_tenant = @account
#     EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
#     # EmailSystemAdmin.configure(@current_account, current_system_admin)
#   # Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
#     # set_current_tenant(@account)
#   rescue ActiveRecord::RecordNotFound
#     render json: { error: 'Invalid tenant' }, status: :not_found
  
    
#   end



#   def set_time_zone
#   Rails.logger.info "Setting time zone"
#   Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
#     Rails.logger.info "Setting time zone #{Time.zone}"

# end



#   # GET /hotspot_vouchers or /hotspot_vouchers.json
#   # def index

#   #   @hotspot_vouchers = HotspotVoucher.all.order(created_at: :desc)
#   #   render json: @hotspot_vouchers
  
#   # end


# def index
#    host = request.headers['X-Subdomain']
#     @account = Account.find_by!(subdomain: host)
#     # @hotspot_vouchers = HotspotVoucher.where(account_id: @account.id).order(created_at: :desc)
#   @hotspot_vouchers =  HotspotVoucher
#                         .where(account_id: @account.id)
#                         .includes(:hotspot_mpesa_revenue, :hotspot_package)
#                         .order(created_at: :desc)

#                         package_names = @hotspot_vouchers.map(&:package).compact.uniq

# packages_by_name = HotspotPackage.where(name: package_names, account_id: @account.id)
#                                   .index_by(&:name)

# router_names = packages_by_name.values.map(&:nas_router).compact.uniq

# # 2. Cache each router's active-user list, keyed by router name via find_by
# active_by_router = Rails.cache.fetch("active_users_#{@account.id}", expires_in: 10.seconds) do
#   router_names.each_with_object({}) do |router_name, hash|
#     nas = NasRouter.find_by(name: router_name, account_id: @account.id)
#     next unless nas

#     begin
#       resp = RestClient::Request.execute(
#         method: :get,
#         url: "http://#{nas.ip_address}/rest/ip/hotspot/active",
#         user: nas.username, password: nas.password,
#         timeout: 3, open_timeout: 2
#       )
#       hash[router_name] = JSON.parse(resp.body).map { |u| u["user"] }
#     rescue
#       hash[router_name] = []
#     end
#   end
# end

# render json: @hotspot_vouchers, each_serializer: HotspotVoucherSerializer,
#        packages_by_name: packages_by_name,
#        active_by_router: active_by_router  
# end








#    def logout_user
#   host = request.headers['X-Subdomain']
#   @account = Account.find_by!(subdomain: host)

#   voucher = HotspotVoucher.find_by(voucher: params[:voucher])
#   return render json: 'Voucher not found', status: :not_found unless voucher

#   package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
#   return render json: 'Package not found', status: :unprocessable_entity unless package

#   nas = NasRouter.find_by(name: package.nas_router, account_id: voucher.account_id)
#   return render json: 'Router not found', status: :unprocessable_entity unless nas

#   begin
#     active_users = RestClient::Request.execute(
#       method: :get,
#       url: "http://#{nas.ip_address}/rest/ip/hotspot/active",
#       user: nas.username,
#       password: nas.password
#     )

#     users = JSON.parse(active_users.body)
#     active = users.find { |u| u["user"] == voucher.voucher }

#     unless active
#       return render json: 'User is not currently online', status: :unprocessable_entity
#     end

#     response = RestClient::Request.execute(
#       method: :post,
#       url: "http://#{nas.ip_address}/rest/ip/hotspot/active/remove",
#       user: nas.username,
#       password: nas.password,
#       payload: { ".id": active[".id"] }.to_json,
#       headers: { content_type: :json }
#     )

#     if response.code == 200
#       HotspotVoucherChannel.broadcast_to(@account, {
#         type: "voucher_online",
#         is_online: false,
#         voucher: voucher,
#         id: voucher.id
#       })

#       render json: 'Successfully logged out user', status: :ok
#     else
#       render json: 'Failed to log out user', status: :unprocessable_entity
#     end

#   rescue RestClient::Unauthorized
#     Rails.logger.info "REST auth failed for router #{nas.ip_address}"
#     render json: 'Router authentication failed', status: :unprocessable_entity

#   rescue RestClient::ExceptionWithResponse => e
#     Rails.logger.info "MikroTik REST error on #{nas.ip_address}: #{e.response}"
#     render json: 'Router error', status: :unprocessable_entity

#   rescue StandardError => e
#     Rails.logger.info "REST error logging in device #{nas.ip_address}: #{e.message}"
#     render json: 'Failed to log out user', status: :unprocessable_entity
#   end
# end




# def transaction_status_result
#   raw_body = request.body.read
#   Rails.logger.info "MPESA STATUS CALLBACK: #{raw_body}"

#   data = JSON.parse(raw_body) rescue {}

#   result = data["Result"] || {}

#   result_code = result["ResultCode"]
#   transaction_id = result["TransactionID"]
#   originator_conversation_id = result["OriginatorConversationID"]

#   # Extract ResultParameters array safely
#   params_array = result.dig("ResultParameters", "ResultParameter") || []

#   # Convert array to hash
#   params_hash = params_array.each_with_object({}) do |item, hash|
#     hash[item["Key"]] = item["Value"]
#   end

#   receipt_no = params_hash["ReceiptNo"]
#   amount = params_hash["Amount"]
#   # phone_and_name = params_hash["DebitPartyName"]
#   transaction_status = params_hash["TransactionStatus"]
#   finalised_time = params_hash["FinalisedTime"]

#   customer_phone_number = params_hash["DebitPartyName"].split(' - ')[0]
#   customer_name = params_hash["DebitPartyName"].split(' - ')[1]
  

# #   active_status = HotspotVoucher.find_by(phone: customer_phone_number,
# #    status: 'active')
# #   #  receipt_no = HotspotVoucher.find_by(phone: customer_phone_number).hotspot_mpesa_revenue.reference
# # voucher_code = HotspotVoucher.find_by(phone: customer_phone_number,
# #    status: 'active').voucher

#    active_session = TemporarySession.find_by(
# phone_number: customer_phone_number,
# status: 'pending'
#    )
# hotspot_package = HotspotPackage.find_by(name: active_session.hotspot_package,
# account_id: active_session.account_id
# )
#   # active_status = HotspotVoucher.find_or_create_by(phone: customer_phone_number,
#   #  status: 'active')
#   #  
  
#     #   hotspot_mpesa_revenue = HotspotMpesaRevenue.find_by(
#     #           reference: receipt_no,
#     #  )

# unless HotspotMpesaRevenue.exists?(reference: receipt_no)
#   found_revenue = HotspotMpesaRevenue.find_or_create_by(
#     reference: receipt_no,
#     amount: amount,
#     voucher: active_session.voucher_code,
#     payment_method: "Mpesa",
#     time_paid: finalised_time,
#     name: customer_name,
#     account_id: active_session.account_id,
#     hotspot_voucher_id: active_session.hotspot_voucher_id
#   )



#    broadcast_hotspot_payment(
#     account_id: active_session.account_id,
#     kind: 'voucher',
#     amount: amount,
#     package: active_session.hotspot_package,
#     name: customer_name,
#     phone: customer_phone_number,
#     payment_method: 'Mpesa',
#     reference: receipt_no
#   )
# end



# if_expired = found_revenue.hotspot_voucher.expiration < Time.current

# if if_expired
#   Rails.logger.info "Voucher expired"
#   return render json: { error: 'Voucher expired' }, status: :unprocessable_entity
  
# end

    


#   voucher = HotspotVoucher.find_or_create_by(
#       voucher: active_session.voucher_code,

# )

# voucher.update(
#   package: active_session.hotspot_package,
#   phone: active_session.phone_number,
  
#   ip: active_session.ip,
#   hotspot_package_id: hotspot_package.id,
# account_id: active_session.account_id)
# voucher.save!


# # voucher_expiration = HotspotSetting.find_by(account_id: active_session.account_id).voucher_expiration


# voucher_expiration = HotspotSetting.find_by(account_id: active_session.account_id)&.voucher_expiration
#  use_radius = router_uses_radius?




#  if use_radius
   
# if voucher_expiration == 'Real-time expiration'
# #  calculate_expiration_login_with_voucher(hotspot_package, voucher, session.account_id)

#   calculate_expiration(active_session.hotspot_package, voucher,
#  active_session.account_id)
# create_voucher_radcheck(active_session.voucher_code,
#       active_session.hotspot_package, 
# active_session.account_id)

# else

#   calculate_expiration(active_session.hotspot_package, voucher,
#  active_session.account_id)

 
#   create_voucher_radcheck_accumulated_sessions(active_session.voucher_code,
#       active_session.hotspot_package, 
# active_session.account_id)
# end
#  else
#    calculate_expiration(active_session.hotspot_package, voucher,
#  active_session.account_id)

# if voucher_expiration == 'Real-time expiration'
  
#    sync_voucher_natively(voucher)
# else
# sync_voucher_natively_realtime_expiration(voucher)  
# end
#  end


# #      create_voucher_radcheck(active_session.voucher_code,
# #       active_session.hotspot_package, 
# # active_session.account_id)




# found_revenue.update(hotspot_voucher_id: voucher.id)

# nas_routers = NasRouter.where(account_id: active_session.account_id, 
# )
# nas_routers.each do |nas|
#   begin
#     response = RestClient::Request.execute(
#       method: :post,
#       url: "http://#{nas.ip_address}/rest/ip/hotspot/active/login",
#       user: nas.username,
#       password: nas.password,
#       payload: {
#         ip: active_session.ip,
#         user: active_session.voucher_code,
#         password: active_session.voucher_code
#       }.to_json,
#       headers: {
#         content_type: :json,
#         accept: :json
#       }
#     )



       
#     if response.code == 200
 
      
       


# voucher.update(status: 'used', login_by: 'Trasnsaction Code')
#        active_session.update(
#         paid: true, connected: true,
#         status: 'used'
#        )
#     end

#   rescue RestClient::Unauthorized
#     Rails.logger.info "REST auth failed for router #{nas.ip_address}"

#   rescue RestClient::ExceptionWithResponse => e
#     Rails.logger.info "MikroTik REST error on #{nas.ip_address}: #{e.response}"

#   rescue StandardError => e
#     Rails.logger.info "REST error logging in device #{active_session.ip}: #{e.message} on router #{nas.ip_address}"
#   end
# end



# end





# def login_with_receipt_number

#   shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.short_code
# passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.passkey
# consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_key
# consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_secret
# initiator = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.api_initiator_username
# security_credentials = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.api_initiator_password
# host = request.headers['X-Subdomain']
# ip = params[:ip]
# mac = params[:mac]



# transaction_id = params[:receipt_number]
#   transaction_status_query = TransactionStatusService.initiate_transaction_status_query(
#    shortcode,passkey,consumer_key,
#       consumer_secret,transaction_id,initiator,security_credentials,host
#   )
# # receipt_no = HotspotVoucher.find_by(phon: customer_phone_number).hotspot_mpesa_revenue.reference
#   transaction_status_query_response = transaction_status_query[:response]
#   Rails.logger.info("Transaction Status Query Response: #{transaction_status_query_response}")

# # Find the record once
# mpesa_revenue = HotspotMpesaRevenue.find_by(reference: transaction_id)

# unless mpesa_revenue
#   return render json: { error: 'Transaction does not exist, please wait we are checking your payment....... ' }, status: :not_found
# end


# # Safely check expiration through the association
# if mpesa_revenue.hotspot_voucher&.expiration.present? && 
#    mpesa_revenue.hotspot_voucher.expiration < Time.current
#   return render json: { error: 'Session expired for voucher or username' }, status: :forbidden
# end


#   # if transaction_status_query[:success]
    
# # present_voucher_or_username = HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.expiration.present?


# nas_routers = NasRouter.where(account_id: mpesa_revenue.account_id)

# # if present_voucher_or_username
#   voucher_code = HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.voucher

# voucher_object_going_to_sync_natively = HotspotVoucher.find_by(voucher_code: voucher_code)
    
#   use_radius = router_uses_radius?

# if use_radius
#   if mpesa_revenue.hotspot_voucher.expiration.nil? 
#   create_voucher_radcheck(mpesa_revenue.hotspot_voucher.voucher, 
#   mpesa_revenue.hotspot_voucher.hotspot_package.name, 
#   mpesa_revenue.account_id)


#     calculate_expiration_login_with_voucher(
#   mpesa_revenue.hotspot_voucher.hotspot_package, 
# mpesa_revenue.hotspot_voucher, mpesa_revenue.account_id)
#   end
# else
# sync_voucher_natively(voucher_object_going_to_sync_natively)
# if mpesa_revenue.hotspot_voucher.expiration.nil? 
 
#     calculate_expiration_login_with_voucher(
#   mpesa_revenue.hotspot_voucher.hotspot_package, 
# mpesa_revenue.hotspot_voucher, mpesa_revenue.account_id)
#   end


# end




    

#   nas_routers.each do |nas|
#   begin
#     response = RestClient::Request.execute(
#       method: :post,
#       url: "http://#{nas.ip_address}/rest/ip/hotspot/active/login",
#       user: nas.username,
#       password: nas.password,
#       payload: {
#         ip: ip,
#         user: voucher_code,
#         password: voucher_code
#       }.to_json,
#       headers: {
#         content_type: :json,
#         accept: :json
#       }
#     )

      


#     if response.code == 200



#    HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.update!(status:"used",
#    login_by:'Transaction Code', 
#       last_logged_in: Time.now,
#       used_voucher: true)

#        package = HotspotPackage.find_by(name: HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.package)
#        expiration_time = HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.expiration
#        TemporarySession.find_by(ip: ip, mac: mac).update(paid: true, connected: true)
#        render json: { message: 'Connected successfully', 
#        device_ip: ip, username: voucher_code, 
#        expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"), 
#        package: package }, status: :ok
#     end

#   rescue RestClient::Unauthorized
#     Rails.logger.info "REST auth failed for router #{nas.ip_address}"

#   rescue RestClient::ExceptionWithResponse => e
#     Rails.logger.info "MikroTik REST error on #{nas.ip_address}: #{e.response}"

#   rescue StandardError => e
#     # Rails.logger.info "REST error logging in device #{active_status.ip}: #{e.message}"
#   end



# end

    
#   # else
#   #   render json: { error: 'Failed to fetch transaction status' }, status: :unprocessable_entity
#   # end

# end






#   def hotspot_traffic
#   account_id = ActsAsTenant.current_tenant&.id
#   use_radius = router_uses_radius?

#   # ← cache key now scoped per-tenant AND per-mode, so radius/native
#   # accounts (and different tenants) never share cached data
#   cache_key = "hotspot_traffic_#{account_id}_#{use_radius}_#{Time.current.beginning_of_minute.to_i}"

#   hotspot_data = Rails.cache.fetch(cache_key, expires_in: 10.seconds) do
#     if use_radius
#       fetch_hotspot_traffic_via_radius
#     else
#       fetch_hotspot_traffic_natively(account_id)
#     end
#   end

#   hotspot_data[:cache_hit] = true unless hotspot_data[:cache_hit]

#   render json: hotspot_data
# end


# # ── Existing RadAcct-based logic, unchanged, just extracted ──
# def fetch_hotspot_traffic_via_radius
#   total_bytes = 0
#   total_bytes_upload_download = 0
#   total_bytes_upload = 0
#   total_bytes_download = 0

#   active_sessions_upload_download = RadAcct.where(
#     acctstoptime: nil,
#     framedprotocol: ''
#   ).where('acctupdatetime > ?', 3.minutes.ago)

#   active_sessions = RadAcct.where(
#     acctstoptime: nil,
#     framedprotocol: ""
#   ).where('acctupdatetime > ?', 3.minutes.ago)

#   active_sessions_upload_download.each do |session|
#     download_bytes = session.acctinputoctets || 0
#     upload_bytes = session.acctoutputoctets || 0
#     total_bytes_download += download_bytes
#     total_bytes_upload += upload_bytes
#     session_total = download_bytes + upload_bytes
#     total_bytes_upload_download += session_total
#   end

#   active_user_data = active_sessions.map do |session|
#     download_bytes = session.acctinputoctets || 0
#     upload_bytes = session.acctoutputoctets || 0
#     session_total = download_bytes + upload_bytes
#     total_bytes += session_total

#     {
#       username: session.username,
#       ip_address: session.framedipaddress.to_s,
#       mac_address: session.callingstationid,
#       up_time: format_uptime(session.acctsessiontime),
#       download: format_bytes(download_bytes),
#       upload: format_bytes(upload_bytes),
#       start_time: session.acctstarttime&.strftime("%B %d, %Y at %I:%M %p") || "Unknown",
#       nas_port: session.nasportid,
#       last_update: session.acctupdatetime&.iso8601 || Time.current.iso8601
#     }
#   end

#   {
#     active_user_count: active_user_data.size,
#     total_upload: format_bytes(total_bytes_upload),
#     total_download: format_bytes(total_bytes_download),
#     total_bandwidth: format_bytes(total_bytes_upload_download),
#     users: active_user_data,
#     timestamp: Time.current.iso8601,
#     cache_hit: false
#   }
# end

# # ── New native MikroTik REST logic, used when use_radius is false ──
# def fetch_hotspot_traffic_natively(account_id)
#   nas_routers = NasRouter.where(account_id: account_id)

#   total_bytes_upload = 0
#   total_bytes_download = 0
#   active_user_data = []

#   nas_routers.each do |nas|
#     begin
#       response = RestClient::Request.execute(
#         method: :get,
#         url: "http://#{nas.ip_address}/rest/ip/hotspot/active",
#         user: nas.username,
#         password: nas.password,
#         timeout: 5,
#         open_timeout: 3
#       )

#       users = JSON.parse(response.body)
#       next unless users.is_a?(Array)

#       users.each do |user|
#         download_bytes = user["bytes-in"].to_i
#         upload_bytes = user["bytes-out"].to_i
#         total_bytes_download += download_bytes
#         total_bytes_upload += upload_bytes

#         active_user_data << {
#           username: user["user"],
#           ip_address: user["address"],
#           mac_address: user["mac-address"],
#           up_time: user["uptime"],
#           download: format_bytes(download_bytes),
#           upload: format_bytes(upload_bytes),
#           start_time: nil,
#           nas_port: nil,
#           last_update: Time.current.iso8601
#         }
#       end

#     rescue RestClient::Unauthorized
#       Rails.logger.error "hotspot_traffic: REST auth failed for router #{nas.ip_address}"
#       next
#     rescue RestClient::ExceptionWithResponse => e
#       Rails.logger.error "hotspot_traffic: MikroTik REST error on #{nas.ip_address}: #{e.response}"
#       next
#     rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
#       Rails.logger.error "hotspot_traffic: Timed out reaching router #{nas.ip_address}"
#       next
#     rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
#       Rails.logger.error "hotspot_traffic: Router #{nas.ip_address} unreachable: #{e.message}"
#       next
#     rescue StandardError => e
#       Rails.logger.error "hotspot_traffic: Failed to fetch from #{nas.ip_address}: #{e.message}"
#       next
#     end
#   end

#   total_bandwidth = total_bytes_download + total_bytes_upload

#   {
#     active_user_count: active_user_data.size,
#     total_upload: format_bytes(total_bytes_upload),
#     total_download: format_bytes(total_bytes_download),
#     total_bandwidth: format_bytes(total_bandwidth),
#     users: active_user_data,
#     timestamp: Time.current.iso8601,
#     cache_hit: false
#   }
# end






# def check_payment_status
#   raw_body = request.body.read

#   data = JSON.parse(raw_body) rescue {}
#   bill_ref = data["BillRefNumber"]

#   if bill_ref.start_with?("hotspot_")
#     # Remove "hotspot_" prefix and extract session_id and voucher_code
#     parts = bill_ref.sub("hotspot_", "").split("_")
#     session_id = parts[0]
#     voucher_code = parts[1]
#         session = TemporarySession.find_by(session: session_id, 
#         )



# if session&.payment_type == 'device_binding'

#   tv_plan = TvPlan.find_by(id: session.tv_plan_id, account_id: session.account_id)
#       # nas_router_tv_package = NasRouter.find_by(name: tv_plan.nas_router, account_id: tv_plan.account_id)
#       nas_router_tv_package = NasRouter.find_by(id: tv_plan.nas_router_id, account_id: tv_plan.account_id)

#   binding = IpBinding.create!(
#     name:        session&.device_name,
#     mac:         session&.device_mac,
#     package:     tv_plan&.name,
#     ip:          session&.ip,
#     tv_plan_id:  tv_plan&.id,
#     phone:       session&.phone_number,
#     source:      'tv_plan_purchase',
#     status:      'active',
#     device_type: session&.device_type,
#     account_id:  session&.account_id,
#     router_id:   nas_router_tv_package&.id,
#     expiry:      tv_plan ? tv_plan_expiration(tv_plan) : nil
#   )

#   HotspotMpesaRevenue.create!(
#     amount: data["TransAmount"], voucher: "DEVICE-#{binding.mac}",
#     reference: data["TransID"], payment_method: "Mpesa",
#     time_paid: data["TransTime"], account_id: session.account_id,
#     name: data["FirstName"], phone_number: session.phone_number,
#     status: "Completed",
#     payment_type: "tv_plan",          # ← NEW: lets admin filter/badge these
#     tv_plan_id: tv_plan&.id,          # ← NEW
#     device_name: binding.name         # ← NEW
#   )


# broadcast_hotspot_payment(
#     account_id: session.account_id,
#     kind: 'tv_plan',
#     amount: data["TransAmount"],
#     package: tv_plan&.name,
#     name: data["FirstName"],
#     phone: session.phone_number,
#     payment_method: 'Mpesa',
#     reference: data["TransID"]
#   )


#   if nas_router_tv_package

#     begin
#        mikrotik_add_binding_direct(binding, nas_router_tv_package)              
#     mikrotik_add_queue_for_tv_plan(binding, tv_plan, nas_router_tv_package) if tv_plan


#     rescue => e
#           Rails.logger.error "MikroTik binding failed for #{binding.mac}: #{e.message}"

#           Rails.logger.error e.backtrace.join("\n")

#     end
#   end
#   send_tv_plan_confirmation_sms(binding, tv_plan, session)   # ← NEW: was defined but never called

#   session.update!(connected: true, status: 'used', paid: true)
#   head :ok
#   return
# end


#  hotspot_package = HotspotPackage.find_by(
#       name:       session&.hotspot_package,
#       account_id: session&.account_id,
#   )

#     nas_router = NasRouter.find_by(name: hotspot_package&.nas_router, account_id: hotspot_package&.account_id)



  
#         # voucher = HotspotVoucher.find_by(voucher: voucher_code)
# hotspot_package = HotspotPackage.find_by(name: session.hotspot_package,
# account_id: session.account_id

# )
#         voucher = HotspotVoucher.create!(
#   package: session.hotspot_package,
#   phone: session.phone_number,
#   voucher: session.voucher_code,
#   mac: session.mac,
#   ip: session.ip,
#   checkout_request_id: session.checkout_request_id,
# account_id: session.account_id,
#   hotspot_package_id: hotspot_package.id,
#   status: 'active'
# )
#  session.update(hotspot_voucher_id: voucher.id)




# # company_name = CompanySetting.find_by(account_id: session.account_id).company_name

# voucher_expiration = HotspotSetting.find_by(account_id: session.account_id)&.voucher_expiration
 
#  use_radius = router_uses_radius_payment(session.account_id)
#  if use_radius
#    if voucher_expiration == 'Real-time expiration'
#  calculate_expiration_login_with_voucher(hotspot_package, voucher, session.account_id)

# create_voucher_radcheck(voucher_code, session.hotspot_package, 
# session.account_id)

# else
#    calculate_expiration_login_with_voucher(hotspot_package, voucher, session.account_id)

#   create_voucher_radcheck_accumulated_sessions(voucher_code, session.hotspot_package, 
# session.account_id)
# end
#  else
#      calculate_expiration_login_with_voucher(hotspot_package, voucher, session.account_id)

# if voucher_expiration == 'Real-time expiration'
  
#    sync_voucher_natively(voucher)
# else
# sync_voucher_natively_realtime_expiration(voucher)  
# end
#  end



# SendSmsHotspotService.send_sms(voucher.voucher, data, session.checkout_request_id,
# )


# broadcast_hotspot_payment(
#   account_id: session.account_id,
#   kind: 'voucher',
#   amount: data["TransAmount"],
#   package: session.hotspot_package,
#   name: data["FirstName"],
#   phone: session.phone_number,
#   payment_method: 'Mpesa',
#   reference: data["TransID"]
# )
#   if nas_router
#   begin
#     response = RestClient::Request.execute(
#       method: :post,
#       url: "http://#{nas_router.ip_address}/rest/ip/hotspot/active/login",
#       user: nas_router.username,
#       password: nas_router.password,
#       payload: {
#         ip: session.ip,
#         user: voucher_code,
#         password: voucher_code
#       }.to_json,
#       headers: {
#         content_type: :json,
#         accept: :json
#       },
#       timeout: 5,
#       open_timeout: 3
#     )

#     if response.code == 200
#       session.update!(connected: true, status: "used", paid: true)

#       voucher.update!(
#         status: "used",
#         last_logged_in: Time.current,
#         used_voucher: true,
#         login_by: "Voucher Code"
#       )
#     end

#   rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
#     Rails.logger.info "Router #{nas_router.ip_address} timed out during login"

#   rescue RestClient::Unauthorized
#     Rails.logger.info "REST auth failed for router #{nas_router.ip_address}"

#   rescue RestClient::ExceptionWithResponse => e
#     Rails.logger.info "MikroTik REST error on #{nas_router.ip_address}: #{e.response}"

#   rescue StandardError => e
#     Rails.logger.info "REST error logging in device #{session.ip}: #{e.message}"
#   end
# else
#   Rails.logger.warn "No router found for account #{session.account_id}"
# end

# elsif bill_ref.start_with?("smswallet_")
#   # bill_ref = "smswallet_<account_id>_<txn_id>"
#   parts = bill_ref.sub("smswallet_", "").split("_")
#   account_id = parts[0]
#   txn_id = parts[1]

#   txn = TenantSmsWalletTransaction.find_by(id: txn_id, account_id: account_id)
#   unless txn
#     Rails.logger.warn "check_payment_status: no sms wallet txn for #{bill_ref}"
#     head :ok and return
#   end

#   # Idempotency guard — M-Pesa retries confirmation callbacks that don't
#   # get acked fast enough, which would otherwise double-credit the wallet.
#   if txn.status == 'completed'
#     Rails.logger.info "check_payment_status: sms wallet txn #{txn.id} already completed, ignoring duplicate callback"
#     head :ok and return
#   end

#   paid_amount = data["TransAmount"].to_f
#   wallet = TenantSmsWallet.find_by(account_id: account_id)

#   if paid_amount >= txn.amount.to_f
#     wallet.complete_purchase!(txn, paid_amount: paid_amount)
#     Rails.logger.info "SMS wallet credited: account #{account_id}, +#{txn.quantity} credits"
#   else
#     txn.update!(status: 'underpaid')
#     Rails.logger.warn "SMS wallet purchase underpaid: expected #{txn.amount}, got #{paid_amount}"
#   end


# elsif data["BillRefNumber"].starts_with?("INV")
#   bill_ref    = data["BillRefNumber"]
#   paid_amount = data["TransAmount"].to_i

#   invoice = Invoice.find_by(invoice_number: bill_ref)

#   unless invoice
#     Rails.logger.warn "check_payment_status: no invoice found for #{bill_ref}"
#     head :ok and return
#   end

#   # Record the payment regardless of whether it fully settles the invoice —
#   # this is now the system admin's source of truth for "what did this ISP
#   # actually pay", independent of the invoice's current status.
#   ActsAsTenant.with_tenant(Account.find_by(id: invoice.account_id)) do
#     InvoicePayment.find_or_create_by!(reference: data["TransID"]) do |p|
#       p.invoice_id    = invoice.id
#       p.account_id    = invoice.account_id
#       p.phone_number  = data["MSISDN"] || data["DebitPartyMSISDN"]
#       p.payer_name    = data["FirstName"]
#       p.amount        = paid_amount
#       p.paid_at       = Time.current
#       p.status        = paid_amount >= invoice.total.to_i ? 'completed' : 'partial'
#     end
#   end

#   if invoice.status == 'unpaid' && invoice.total.to_i == paid_amount
#     invoice.update!(
#       status: 'paid',
#       amount_paid: paid_amount,
#       total: data["TransAmount"],
#       plan_name: "Hotspot And PPPOE Plan"
#     )

#     tenant = Account.find_by(id: invoice.account_id)
#     tenant.hotspot_and_dial_plan.update(
#       name: 'Hotspot And PPPOE Plan',
#       # expiry: Time.current + 30.days,
#       expiry: (tenant.hotspot_and_dial_plan.expiry || Time.current) + 30.days,
#       expiry_days: 30
#     )
#   end



  
#   else

#  bill_ref = data["BillRefNumber"]

#   # subscriber_account_number = Subscriber.find_by(ref_no:  bill_ref).ref_no
  
#   found_subscriber = Subscriber.find_by(ref_no:  bill_ref)
#   nas_routers = NasRouter.where(account_id: found_subscriber.account_id)
#         subscription = Subscription.find_by(subscriber_id: found_subscriber.id, 
#         account_id: found_subscriber.account_id)
# paid_amount = data["TransAmount"].to_i
         

        
#   subscriber_phone_number = Subscriber.find_by(id: subscription.subscriber_id).phone_number

# pppoe_package = Package.find_by(name: subscription.package_name)

# total_wallet_balance = PpPoeMpesaRevenue
#   .where(account_number: bill_ref)
#   .sum(:amount)


#    pppoe_revenue = PpPoeMpesaRevenue.create(
#       amount: data["TransAmount"],
#       payment_method: "Mpesa",
#       time_paid: data["TransTime"],
#       account_number:  bill_ref,
#       reference: data["TransID"],
#       customer_name: data['FirstName'],
#       payment_type: "Deposit",
#       account_id: found_subscriber.account_id,
#       subscriber_id: subscription.subscriber_id

#     )

#     if pppoe_package.price === data["TransAmount"].to_i
#      SubscriberTransaction.create!(
#             transaction_type: 'Payment',
#             debit: pppoe_revenue.amount,
#             date:  pppoe_revenue.time_paid,
#             title:  pppoe_package.name,
#             description: "Payment for internet subscription",
#             account_id:  pppoe_revenue.account_id,
#             subscriber_id: pppoe_revenue.subscriber_id
#           )




#           SubscriberTransaction.create!(
#             transaction_type: 'Deposit',
#             credit: pppoe_revenue.amount,
#             date:  pppoe_revenue.time_paid,
#             title:   pppoe_revenue.reference,
#             description: "Payment made via M-Pesa",
#             account_id:  pppoe_revenue.account_id,
#             subscriber_id: pppoe_revenue.subscriber_id
#           )

#     else
#       SubscriberTransaction.create!(
#             transaction_type: 'Deposit',
#             credit: pppoe_revenue.amount,
#             date:  pppoe_revenue.time_paid,
#             title:  pppoe_revenue.reference,
#             description: "Payment made via M-Pesa",
#             account_id:  pppoe_revenue.account_id,
#             subscriber_id: pppoe_revenue.subscriber_id)

#     end
#        @subscriber_wallet_balance = SubscriberWalletBalance.first_or_initialize(
#         subscriber_id: pppoe_revenue.subscriber_id,
#         amount: total_wallet_balance,
#        account_id: pppoe_revenue.account_id
#       )
#       @subscriber_wallet_balance.update(
#          subscriber_id: pppoe_revenue.subscriber_id,
#         amount: total_wallet_balance,
#        account_id: pppoe_revenue.account_id
#       )
#         # package_amount_paid = data["TransAmount"]
#   # expiration_time = Time.parse(subscription.expiration_date.to_s)


#         # expiration_time > Time.current
#         # paid_right_amount = Package.find_by(
#         #   account_id: subscription.account_id,
#  #   amount: package_amount_paid
#         # )

#         if pppoe_package.price === data["TransAmount"].to_i

#  invoice = SubscriberInvoice
#   .where(
#     subscriber_id: found_subscriber.id,
#     account_id: found_subscriber.account_id,
#     status: "unpaid"
#   )
#   .order(:invoice_date)
#   .firs
#        invoice.update!(status: 'paid', description: "Invoice paid for
#            wifi package => #{subscription.package_name}",
           
#            amount: paid_amount,
#            )
#         end

          
# # company_name, account_no, tenant
# company_name = CompanySetting.find_by(account_id: subscription.account_id)
# # send_invoice_paid_notification = SubscriberSetting.find_by(account_id: found_subscriber.account_id)&.invoice_created_or_paid

#         #   if send_invoice_paid_notification
#         # SendInvoicePaidJob.perform_now(
#         #   company_name.company_name,
#         #   bill_ref,
#         #   invoice.account,
#         #   subscriber_phone_number
#         # )
#         #   end


#         if pppoe_package.price === data["TransAmount"].to_i
#            SendInvoicePaidJob.perform_now(
#           company_name.company_name,
#           bill_ref,
#           found_subscriber.account,
#           subscriber_phone_number
#         )

#          subscription.update(invoice_expired_created_at:  nil)


#           if subscription.status === 'blocked'
#              subscription.update!(status: 'active', expiry: Time.current + 30.days)

#           end


#             if subscription.status === 'blocked'

# nas_routers.each do |nas|
#       Rails.logger.info "PPPOE payment received: #{bill_ref}"
#     #  ping_result = system("ping -c 1 -W 2 #{nas.ip_address}")

#       Net::SSH.start(nas.ip_address, nas.username, password: nas.password,
         
#       verify_host_key: :never, non_interactive: true) do |ssh|
#           # Correct command to remove active PPPoE session based on pppoe_username
#           command = "/ip firewall address-list remove [find list=aitechs_blocked_list address=#{subscription.ip_address}]"
          
#           # Execute the command
#           ssh.exec!(command)
#           if subscription.status === 'blocked'
#              subscription.update!(status: 'active', expiry: Time.current + 30.days)

#           end
#           puts "UnBlocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik."
#         end
#       end
#     end
#       # rescue StandardError => e
#       #   Rails.logger.error "Error removing PPPoE connection for username #{subscription.ppoe_username}: #{e.message}"
#       # end
# end
        

   

   
#   end

#   head :ok
# end






# def payment_and_conected_status
#   # session = TemporarySession.find_by(ip: params[:ip])

#   # if session.paid && session.connected
#   #  render json: { paid: session.paid, connected: session.connected}
#   # end
#   ip  = params[:ip]
#   mac = params[:mac]

#   cache_key = "payment_status:#{ip}:#{mac}"

#   status = Rails.cache.fetch(cache_key, expires_in: 10.seconds) do
#     session = TemporarySession.find_by(ip: ip)

#     {
#       paid: session&.paid || false,
#       connected: session&.connected || false
#     }
#   end

#   render json: status
# end




# # def stk_push_status
# #     shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.short_code || ENV['B2C_SHORTCODE']
# #   passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.passkey || ENV['PASSKEY']
# #   consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_key || ENV['CONSUMER_KEY']
# #   consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_secret || ENV['CONSUMER_SECRET']
# #  checkout_request_id = params[:checkout_request_id]
# # Rails.logger.info "checkout_request_id: #{checkout_request_id}"
# #   stk_push_query = StkStatusService.initiate_stk_query(
# #     shortcode,  passkey,
# #     consumer_key, consumer_secret,checkout_request_id
# #   )


# #   if stk_push_query[:success]
# #     stk_push_query_response = stk_push_query[:response]
# #     render json: { success: true, response: stk_push_query_response }
# #   else
# #     render json: { error: 'Failed to fetch stk push status'}
# #   end


# # end








# def stk_push_status
#   shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.short_code.presence || ENV['B2C_SHORTCODE']
#   passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.passkey.presence || ENV['PASSKEY']
#   consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_key.presence || ENV['CONSUMER_KEY']
#   consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_secret.presence || ENV['CONSUMER_SECRET']

#   checkout_request_id = params[:checkout_request_id]

#   Rails.logger.info "checkout_request_id: #{checkout_request_id}"

#   stk_push_query = StkStatusService.initiate_stk_query(
#     shortcode,
#     passkey,
#     consumer_key,
#     consumer_secret,
#     checkout_request_id
#   )

#   unless stk_push_query[:success]
#     return render json: { error: "Failed to fetch stk push status" }
#   end

#   stk_push_query_response = stk_push_query[:response]

#   revenue = HotspotMpesaRevenue.find_by(
#     checkout_request_id: checkout_request_id
#   )

#   if revenue.present?
#     case stk_push_query_response["ResultCode"].to_s
#     when "0"
#       revenue.update(status: "Completed")

#     when "1037"
#       revenue.update(status: "Pending")

#       when "4999"
#       revenue.update(status: "Pending")

#     else
#       revenue.update(status: "Cancelled")
#     end
#   end

#   render json: {
#     success: true,
#     response: stk_push_query_response
#   }
# end




# def receipt_number_status
#  active_session = TemporarySession.find_by(ip: params[:ip])
#  if active_session
#   render json: { paid: active_session.paid, connected: active_session.connected }
#  else
#   render json: { paid: false, connected: false }
#  end
# end




# # def make_payment
# # host = request.headers['X-Subdomain']

# # plan = ActsAsTenant.current_tenant&.hotspot_and_dial_plan

# #   expired_pppoe = plan&.expiry.present? && plan.expiry <= Time.current



# #   if expired_pppoe
# #     return render json: { error: 'License has expired'}, status: 422  
# #   end

# #   phone_number = params[:phone_number]

# # if phone_number.blank?
# #     return render json: { error: 'Phone number is required to make a payment' }, status: :unprocessable_entity
# #   end

# #   amount = params[:amount]
# #   shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.short_code || ENV['B2C_SHORTCODE']
# #   passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.passkey || ENV['PASSKEY']
# #   consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_key || ENV['CONSUMER_KEY']
# #   consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_secret || ENV['CONSUMER_SECRET']

# # #   session_id = rand(100000..999999).to_s
# # # TemporarySession.create!(
# # #   session: session_id,
# # #   ip: params[:ip],    
# # # )

# # session_id = rand(100000..999999).to_s



# #  tuma_setting = TumaSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
# #   use_tuma = tuma_setting&.enabled && tuma_setting.use_for_hotspot




# #   if use_tuma
# #     full_domain = request.headers['X-Domain']
# #     base_domain = full_domain.to_s.split('.').last(3).join('.') if full_domain.present?
# #     platform_domain = base_domain == "owitech.co.ke" ? "owitech.co.ke" : "aitechs.co.ke"
# #     callback_url = "https://#{host}.#{platform_domain}/api/tuma/hotspot_callback/#{session_id}"

# #     result = TumaService.initiate_stk_push(
# #       tuma_setting, amount: amount, phone: phone_number,
# #       callback_url: callback_url, description: "Hotspot package #{params[:package]}"
# #     )

# #     if result[:success]
# #       checkout_request_id = result[:response]['checkout_request_id']
# #       session.update!(checkout_request_id: checkout_request_id)
# #       HotspotMpesaRevenue.create!(voucher: voucher_code, amount: amount, payment_method: 'Tuma',
# #         phone_number: phone_number, status: 'Pending', checkout_request_id: checkout_request_id)
# #       return render json: { message: 'Please check your phone to complete the payment', checkout_request_id: checkout_request_id }
# #     else
# #       return render json: { error: result[:error] || 'Failed to initiate Tuma payment' }, status: :unprocessable_entity
# #     end
# #   end


# #       hotspot_payment = MpesaService.initiate_stk_push(phone_number, 
# #       amount,
# #        shortcode,  passkey,
# #         consumer_key, consumer_secret, host,voucher_code,session_id
# #       )
  
# #  stk_response = hotspot_payment[:response]
# #  checkout_request_id = stk_response['CheckoutRequestID']
# # #  merchant_request_id = stk_response['MerchantRequestID']





# # session = TemporarySession.find_or_initialize_by(ip: params[:ip],
# # session: session_id,
# # paid: false, 
# # connected: false,
# # hotspot_package: params[:package],
# # voucher_code: voucher_code,
# # phone_number: phone_number,
# # mac: params[:mac],
# # status: 'pending',
# # checkout_request_id: checkout_request_id,
# #  payment_gateway: use_tuma ? 'tuma' : 'mpesa'

# # )





# # session.save!



# #       if hotspot_payment[:success]
# # # voucher_record = HotspotVoucher.create!(
# # #   package: params[:package],
# # #   phone: phone_number,
# # #   voucher: voucher_code,
# # #   mac: params[:mac],
# # #   ip: params[:ip],
# # #   checkout_request_id: checkout_request_id,
# # #   merchant_request_id: merchant_request_id,

# # #   payment_status: 'pending'

# # # )

# # # create_voucher_radcheck(voucher_code, params[:package], 
# # # voucher_record.account_id)

# # # calculate_expiration(params[:package], voucher_record)


# # HotspotMpesaRevenue.create!(
# #   voucher: voucher_code,
# #   amount: amount,
# #   payment_method: "Mpesa",
# #   phone_number: phone_number,
# #   status: "Pending",
# #   checkout_request_id: checkout_request_id
# # )



# #         render json: {
# #           message: 'Please check your phone to complete the payment',
# #           checkout_request_id: checkout_request_id
# #         }
# #       else
# #         render json: { error: 'Failed to initiate payment' }, status: :unprocessable_entity
# #       end
# # end



# def payment_reference_status
#   reference = params[:reference] || params[:checkout_request_id]
#   revenue = HotspotMpesaRevenue.find_by(checkout_request_id: reference)
#   return render json: { error: 'Not found' }, status: :not_found unless revenue

#   session = TemporarySession.find_by(checkout_request_id: reference)

#   render json: {
#     success: true,
#     status: revenue.status,          # 'Pending' | 'Completed' | 'Cancelled'
#     connected: session&.connected || false,
#     package: session&.hotspot_package
#   }
# end





# # def make_payment
# #   host = request.headers['X-Subdomain']

# #   plan = ActsAsTenant.current_tenant&.hotspot_and_dial_plan
# #   expired_pppoe = plan&.expiry.present? && plan.expiry <= Time.current

# #   if expired_pppoe
# #     return render json: { error: 'License has expired'}, status: 422  
# #   end

# #   phone_number = params[:phone_number]
# #   if phone_number.blank?
# #     return render json: { error: 'Phone number is required to make a payment' }, status: :unprocessable_entity
# #   end

# #   amount = params[:amount]
# #   shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.short_code || ENV['B2C_SHORTCODE']
# #   passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.passkey || ENV['PASSKEY']
# #   consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_key || ENV['CONSUMER_KEY']
# #   consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_secret || ENV['CONSUMER_SECRET']

# #   voucher_code = generate_voucher_code
# #   session_id = rand(100000..999999).to_s

# #   tuma_setting = TumaSetting.find_by(account_id: ActsAsTenant.current_tenant.id)

# #   active_gateway = PaymentGatewaySetting.active_gateway_for(ActsAsTenant.current_tenant.id, 'hotspot')

# #   tuma_setting = TumaSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
# #   use_tuma = active_gateway == 'tuma' && tuma_setting&.enabled

# #   paystack_setting = PaystackSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
# #   use_paystack = active_gateway == 'paystack' && paystack_setting&.enabled

# #   gateway_label = use_tuma ? 'tuma' : (use_paystack ? 'paystack' : 'mpesa')

# #   temp_session = TemporarySession.find_or_initialize_by(
# #     ip: params[:ip], session: session_id, paid: false, connected: false,
# #     hotspot_package: params[:package], voucher_code: voucher_code,
# #     phone_number: phone_number, mac: params[:mac], status: 'pending',
# #     payment_gateway: gateway_label
# #   )


# #   if use_paystack
# #     reference = "hotspot_#{session_id}_#{voucher_code}"

# #     result = PaystackService.initiate_mobile_money_charge(
# #       paystack_setting, amount: amount, phone: phone_number, email: nil,
# #       reference: reference, metadata: { package: params[:package], session_id: session_id }
# #     )

# #     if result[:success]
# #       temp_session.update!(checkout_request_id: reference)
# #       HotspotMpesaRevenue.create!(
# #         voucher: voucher_code, amount: amount, payment_method: 'Paystack',
# #         phone_number: phone_number, status: 'Pending', checkout_request_id: reference
# #       )
# #       return render json: {
# #         message: result[:display_text].presence || 'Please check your phone to complete the payment',
# #         checkout_request_id: reference
# #       }
# #     else
# #       return render json: { error: result[:error] || 'Failed to initiate Paystack payment' }, status: :unprocessable_entity
# #     end
# #   end
  

# #   if use_tuma
# #     full_domain = request.headers['X-Domain']
# #     base_domain = full_domain.to_s.split('.').last(3).join('.') if full_domain.present?
# #     platform_domain = base_domain == "owitech.co.ke" ? "owitech.co.ke" : "aitechs.co.ke"
# #     callback_url = "https://#{host}.#{platform_domain}/api/tuma/hotspot_callback/#{session_id}"

# #     result = TumaService.initiate_stk_push(
# #       tuma_setting, 
# #       amount: amount, 
# #       phone: phone_number,
# #       callback_url: callback_url, 
# #       description: "Hotspot package #{params[:package]}"
# #     )

# #     if result[:success]
# #       checkout_request_id = result[:response]['checkout_request_id']
# #       # ✅ NOW THIS WORKS
# #       temp_session.update!(checkout_request_id: checkout_request_id)
      
# #       HotspotMpesaRevenue.create!(
# #         voucher: voucher_code, 
# #         amount: amount, 
# #         payment_method: 'Tuma',
# #         phone_number: phone_number, 
# #         status: 'Pending', 
# #         checkout_request_id: checkout_request_id
# #       )
      
# #       return render json: { 
# #         message: 'Please check your phone to complete the payment', 
# #         checkout_request_id: checkout_request_id 
# #       }
# #     else
# #       return render json: { error: result[:error] || 'Failed to initiate Tuma payment' }, status: :unprocessable_entity
# #     end
# #   end

# #   # Fallback to M-Pesa
# #   hotspot_payment = MpesaService.initiate_stk_push(
# #     phone_number, 
# #     amount,
# #     shortcode,  
# #     passkey,
# #     consumer_key, 
# #     consumer_secret, 
# #     host,
# #     voucher_code,
# #     session_id
# #   )
  
# #   stk_response = hotspot_payment[:response]
# #   checkout_request_id = stk_response['CheckoutRequestID']

# #   # ✅ USE temp_session, not session
# #   temp_session.checkout_request_id = checkout_request_id
# #   temp_session.save!

# #   if hotspot_payment[:success]
# #     HotspotMpesaRevenue.create!(
# #       voucher: voucher_code,
# #       amount: amount,
# #       payment_method: "Mpesa",
# #       phone_number: phone_number,
# #       status: "Pending",
# #       checkout_request_id: checkout_request_id
# #     )

# #     render json: {
# #       message: 'Please check your phone to complete the payment',
# #       checkout_request_id: checkout_request_id
# #     }
# #   else
# #     render json: { error: 'Failed to initiate payment' }, status: :unprocessable_entity
# #   end
# # end



# def make_payment
#   host = request.headers['X-Subdomain']

#   plan = ActsAsTenant.current_tenant&.hotspot_and_dial_plan
#   expired_pppoe = plan&.expiry.present? && plan.expiry <= Time.current

#   if expired_pppoe
#     return render json: { error: 'License has expired'}, status: 422  
#   end

#   phone_number = params[:phone_number]
#   if phone_number.blank?
#     return render json: { error: 'Phone number is required to make a payment' }, status: :unprocessable_entity
#   end

#   amount = params[:amount]
#   shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.short_code.presence || ENV['B2C_SHORTCODE']
# passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.passkey.presence || ENV['PASSKEY']
# consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_key.presence || ENV['CONSUMER_KEY']
# consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_secret.presence || ENV['CONSUMER_SECRET']


#   voucher_code = generate_voucher_code
#   session_id = rand(100000..999999).to_s

#   active_gateway = PaymentGatewaySetting.active_gateway_for(ActsAsTenant.current_tenant.id, 'hotspot')

#   tuma_setting = TumaSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
#   use_tuma = active_gateway == 'tuma' && tuma_setting&.enabled

#   paystack_setting = PaystackSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
#   use_paystack = active_gateway == 'paystack' && paystack_setting&.enabled

#   gateway_label = use_tuma ? 'tuma' : (use_paystack ? 'paystack' : 'mpesa')

#   temp_session = TemporarySession.find_or_initialize_by(
#     ip: params[:ip], session: session_id, paid: false, connected: false,
#     hotspot_package: params[:package], voucher_code: voucher_code,
#     phone_number: phone_number, mac: params[:mac], status: 'pending',
#     payment_gateway: gateway_label
#   )

#   if use_paystack
#     reference = "hotspot_#{session_id}_#{voucher_code}"

#     result = PaystackService.initiate_mobile_money_charge(
#       paystack_setting, amount: amount, phone: phone_number, email: nil,
#       reference: reference, metadata: { package: params[:package], session_id: session_id }
#     )

#     if result[:success]
#       temp_session.update!(checkout_request_id: reference)
#       HotspotMpesaRevenue.create!(
#         voucher: voucher_code, amount: amount, payment_method: 'Paystack',
#         phone_number: phone_number, status: 'Pending', checkout_request_id: reference
#       )
#       return render json: {
#         message: result[:display_text].presence || 'Please check your phone to complete the payment',
#         checkout_request_id: reference,
#         gateway: gateway_label  
#       }
#     else
#       return render json: { error: result[:error] || 'Failed to initiate Paystack payment' }, status: :unprocessable_entity
#     end
#   end

#   if use_tuma
#     full_domain = request.headers['X-Domain']
#     base_domain = full_domain.to_s.split('.').last(3).join('.') if full_domain.present?
#     platform_domain = base_domain == "owitech.co.ke" ? "owitech.co.ke" : "aitechs.co.ke"
#     callback_url = "https://#{host}.#{platform_domain}/api/tuma/hotspot_callback/#{session_id}"

#     result = TumaService.initiate_stk_push(
#       tuma_setting,
#       amount: amount,
#       phone: phone_number,
#       callback_url: callback_url,
#       description: "Hotspot package #{params[:package]}"
#     )

#     if result[:success]
#       checkout_request_id = result[:response]['checkout_request_id']
#       temp_session.update!(checkout_request_id: checkout_request_id)

#       HotspotMpesaRevenue.create!(
#         voucher: voucher_code,
#         amount: amount,
#         payment_method: 'Tuma',
#         phone_number: phone_number,
#         status: 'Pending',
#         checkout_request_id: checkout_request_id
#       )

#       return render json: {
#         message: 'Please check your phone to complete the payment',
#         checkout_request_id: checkout_request_id,
#         gateway: gateway_label  
#       }
#     else
#       return render json: { error: result[:error] || 'Failed to initiate Tuma payment' }, status: :unprocessable_entity
#     end
#   end

#   # Fallback to M-Pesa
#   hotspot_payment = MpesaService.initiate_stk_push(
#     phone_number,
#     amount,
#     shortcode,
#     passkey,
#     consumer_key,
#     consumer_secret,
#     host,
#     voucher_code,
#     session_id
#   )

#   # MpesaService can fail before ever reaching Safaricom (e.g. "Error fetching
#   # access token") and return {success: false, error: "..."} with no :response
#   # key at all. Guard on success before touching [:response] so a credential
#   # or network failure returns a clean 422 instead of a 500.
#   unless hotspot_payment[:success]
#     return render json: { error: hotspot_payment[:error] || 'Failed to initiate payment' }, status: :unprocessable_entity
#   end

#   stk_response = hotspot_payment[:response]
#   checkout_request_id = stk_response && stk_response['CheckoutRequestID']

#   unless checkout_request_id
#     return render json: { error: 'Failed to initiate payment: no checkout request ID returned' }, status: :unprocessable_entity
#   end

#   temp_session.checkout_request_id = checkout_request_id
#   temp_session.save!

#   HotspotMpesaRevenue.create!(
#     voucher: voucher_code,
#     amount: amount,
#     payment_method: "Mpesa",
#     phone_number: phone_number,
#     status: "Pending",
#     checkout_request_id: checkout_request_id
#   )

#   render json: {
#     message: 'Please check your phone to complete the payment',
#     checkout_request_id: checkout_request_id,
#     gateway: gateway_label  
#   }
# end



  
# def expired_vouchers
#   expired_voucher = HotspotVoucher.where(status: 'expired').count
#   render json: {expired_voucher: expired_voucher}, status: :ok
# end



# def active_vouchers
#   active_voucher = HotspotVoucher.where(status: 'active').count
#   render json: {active_voucher: active_voucher}, status: :ok

# end





# def send_voucher_to_phone_number
#     company_name = ActsAsTenant.current_tenant&.company_setting&.company_name

#   if params[:phone].present?
#    HotspotVoucher.find_by(voucher: params[:voucher]).update(phone: params[:phone])

# voucher = HotspotVoucher.find_by(voucher: params[:voucher])
# shared_users = HotspotPackage.find_by(name: voucher.package)
#    data = build_voucher_sms_data(voucher, params[:phone], shared_users, company_name)
#   message = render_hotspot_sms('single', data)

# # TenantSmsSenderService.uses_platform?(ActsAsTenant.current_tenant.id)

   
#         if ActsAsTenant.current_tenant&.sms_provider_setting&.sms_provider == "Owitech Bulk SMS"

          
# TenantSmsSenderService.send_sms(params[:phone], message, ActsAsTenant.current_tenant.id, voucher, 
# current_user: current_user)

#       # expiration.strftime("%B %d, %Y at %I:%M %p"), 


#              elsif ActsAsTenant.current_tenant&.sms_provider_setting&.sms_provider == "SMS leopard"
#                send_voucher(params[:phone], params[:voucher],
#                 shared_users, company_name, current_user
#                )
              
            

#              elsif ActsAsTenant.current_tenant&.sms_provider_setting&.sms_provider == "TextSms"
#                send_voucher_text_sms(params[:phone], params[:voucher],
#                shared_users, company_name, current_user
#                )



#                elsif ActsAsTenant.current_tenant&.sms_provider_setting&.sms_provider == "Talk Sasa"
#                send_voucher_talksasa(params[:phone], params[:voucher],
#                shared_users, company_name, current_user
#                )
#              end
         
#            return render json: { message: "Voucher sent successfully" }, status: :ok
           
#           end
          
# end



# #   def create

# #   if params[:package].blank?
# #     render json: { error: "hotspot package is required" }, status: :unprocessable_entity
# #     return
# #   end

# #   if params[:package].blank?
# #         render json: { error: "hotspot package is required" }, status: :unprocessable_entity
# #         return
# #       end
  

# #       @hotspot_voucher = HotspotVoucher.new(
# #       package: params[:package],
# #       shared_users: params[:shared_users],
# #       phone: params[:phone],
# #     )

      
# #     ActivtyLog.create(action: 'create', ip: request.remote_ip,
# #  description: "Created hotspot voucher #{@hotspot_voucher.voucher}",
# #           user_agent: request.user_agent, user: current_user.username || current_user.email,
# #            date: Time.current)

     
# #       create_voucher_radcheck(@hotspot_voucher.voucher, @hotspot_voucher.package)
     
# #       calculate_expiration(params[:package], @hotspot_voucher)
# #         if @hotspot_voucher.save

# #           render json: @hotspot_voucher, status: :created

          
# #         else
# #           render json: @hotspot_voucher.errors, status: :unprocessable_entity 
# #         end
    
# #   end

# def create
#   if params[:package].blank?
#     render json: { error: "hotspot package is required" }, status: :unprocessable_entity
#     return
#   end

#   hotspot_package = HotspotPackage.find_by(name: params[:package])
#   if hotspot_package.nil?
#     render json: { error: "Hotspot package '#{params[:package]}' not found" }, status: :unprocessable_entity
#     return
#   end

#   use_radius = router_uses_radius?

#   number_of_vouchers = params[:number_of_vouchers].to_i
#   number_of_vouchers = 1 if number_of_vouchers < 1

#   created_vouchers = []

#   ActiveRecord::Base.transaction do
#     number_of_vouchers.times do
#       voucher_code = generate_voucher_code

#       @hotspot_voucher = HotspotVoucher.new(
#         package: params[:package],
#         shared_users: params[:shared_users],
#         phone: params[:phone],
#         voucher: voucher_code,
#         hotspot_package_id: hotspot_package.id,
#         status: 'active',
#         sync_status: use_radius ? nil : 'not_synced'
#       )

#       @hotspot_voucher.save!

#       calculate_expiration(params[:package], @hotspot_voucher, @hotspot_voucher.account_id)

#       if use_radius
#         if ActsAsTenant.current_tenant&.hotspot_setting&.voucher_expiration == 'Real-time expiration'
#           create_voucher_radcheck(voucher_code, params[:package], @hotspot_voucher.account_id)
#         else
#           create_voucher_radcheck_accumulated_sessions(voucher_code, params[:package], @hotspot_voucher.account_id)
#         end
#       else
#         # Native MikroTik account - push the user straight to the router.
#         # sync_status/sync_error land on the record so the Sync column
#         # and the manual/bulk sync buttons reflect the real state.
#         sync_voucher_natively(@hotspot_voucher)
#       end

#       created_vouchers << @hotspot_voucher
#     end

#     if number_of_vouchers == 1
#       ActivtyLog.create!(
#         action: 'create',
#         ip: request.remote_ip,
#         description: "Created hotspot voucher #{created_vouchers.first.voucher}",
#         user_agent: request.user_agent,
#         user: current_user.username || current_user.email,
#         date: Time.current
#       )
#     else
#       ActivtyLog.create!(
#         action: 'create',
#         ip: request.remote_ip,
#         description: "Created #{created_vouchers.count} hotspot vouchers for package #{params[:package]}",
#         user_agent: request.user_agent,
#         user: current_user.username || current_user.email,
#         date: Time.current
#       )
#     end
#   end

#   if created_vouchers.any?
#     render json: created_vouchers, status: :created
#   else
#     render json: { error: "Failed to create vouchers" }, status: :unprocessable_entity
#   end

# rescue ActiveRecord::RecordInvalid => e
#   render json: { error: e.message }, status: :unprocessable_entity
# rescue => e
#   render json: { error: "An error occurred: #{e.message}" }, status: :unprocessable_entity
# end




#   def create_voucher_radcheck(hotspot_voucher, package, account_id)

# hotspot_package = "hotspot_#{account_id}_#{package.parameterize(separator: '_')}"




# radcheck = RadCheck.find_or_initialize_by(username: hotspot_voucher,
# account_id: account_id,
# radiusattribute: 
# 'Cleartext-Password')  

# radcheck.update!(op: ':=', value: hotspot_voucher)


# rad_user_group = RadUserGroup.find_or_initialize_by(username: hotspot_voucher,
#  groupname: hotspot_package, priority: 1, account_id: account_id)
# rad_user_group.update!(username: hotspot_voucher, groupname: hotspot_package, priority: 1)


# validity_period_units = HotspotPackage.find_by(name: package, account_id: account_id).validity_period_units
# validity = HotspotPackage.find_by(name: package, account_id: account_id).validity



# expiration_time = case validity_period_units
# when 'days' then Time.current + validity.days
# when 'hours' then Time.current + validity.hours
# when 'minutes' then Time.current + validity.minutes
# end&.strftime("%d %b %Y %H:%M:%S")

# if expiration_time
#   rad_check = RadCheck.find_or_initialize_by(username: hotspot_voucher,
#    account_id: account_id,
#    radiusattribute: 'Expiration')
#   rad_check.update!(op: ':=', value: expiration_time)
# end
# end
  














# def create_voucher_radcheck_accumulated_sessions(hotspot_voucher, package, account_id)

# hotspot_package = "hotspot_#{account_id}_#{package.parameterize(separator: '_')}"




# radcheck = RadCheck.find_or_initialize_by(username: hotspot_voucher,
# account_id: account_id,
# radiusattribute: 
# 'Cleartext-Password')  

# radcheck.update!(op: ':=', value: hotspot_voucher)


# rad_user_group = RadUserGroup.find_or_initialize_by(username: hotspot_voucher,
#  groupname: hotspot_package, priority: 1, account_id: account_id)
# rad_user_group.update!(username: hotspot_voucher, groupname: hotspot_package, priority: 1)


# validity_period_units = HotspotPackage.find_by(name: package, account_id: account_id).validity_period_units
# validity = HotspotPackage.find_by(name: package, account_id: account_id).validity



# seconds =
#   case validity_period_units
#   when "minutes"
#     validity.minutes.to_i
#   when "hours"
#     validity.hours.to_i
#   when "days"
#     validity.days.to_i
#   end

# if seconds
#   rad_check = RadCheck.find_or_initialize_by(username: hotspot_voucher,
#    account_id: account_id,
#    radiusattribute: 'Expiration')
#   rad_check.update!(op: ':=', value: expiration_time)


#   radcheck = RadCheck.find_or_initialize_by(
#   username: hotspot_voucher,
#   account_id: account_id,
#   radiusattribute: "Max-All-Session")
#    rad_check.update!(
#   op: ":=",
#   value: seconds
#  )
# end
# end



#   def create_voucher_radcheck_compensation(hotspot_voucher, package, 
#     account_id)

# hotspot_package = "hotspot_#{account_id}_#{package.parameterize(separator: '_')}"




# radcheck = RadCheck.find_or_initialize_by(username: hotspot_voucher,
# account_id: account_id,
# radiusattribute: 
# 'Cleartext-Password')  

# radcheck.update!(op: ':=', value: hotspot_voucher)

# rad_user_group = RadUserGroup.find_or_initialize_by(username: hotspot_voucher,
#  groupname: hotspot_package, priority: 1, account_id: account_id)
# rad_user_group.update!(username: hotspot_voucher, groupname: hotspot_package, priority: 1)


# rad_reply = RadReply.find_or_initialize_by(username: hotspot_voucher, 
# radiusattribute: '',
# account_id: account_id,
#  op: ':=', value: '5000')
 
# # rad_reply.update!(username: hotspot_voucher, 
# # radiusattribute: 'Idle-Timeout', op: ':=', value: '5000')

# validity_period_units = HotspotPackage.find_by(name: package, account_id: account_id).validity_period_units
# validity = HotspotPackage.find_by(name: package, account_id: account_id).validity

# # Step 1: keep as Time object
# expiration_time = case validity_period_units
# when 'days' then Time.current + validity.days
# when 'hours' then Time.current + validity.hours
# when 'minutes' then Time.current + validity.minutes
# end

# # Step 2: add compensation
# tenant = Account.find_by(id: account_id)
# extra_time = compensation_duration(tenant)

# final_expiration = expiration_time + extra_time

# # Step 3: convert to string ONLY when saving
# formatted_expiration = final_expiration

# if final_expiration
#   rad_check = RadCheck.find_or_initialize_by(
#     username: hotspot_voucher,
#     account_id: account_id,
#     radiusattribute: 'Expiration'
#   )

#   rad_check.update!(op: ':=', value: formatted_expiration.strftime("%d %b %Y %H:%M:%S"))
# end
  

# end












#   # PATCH/PUT /hotspot_vouchers/1 or /hotspot_vouchers/1.json
#   def update
#       @hotspot_voucher = set_hotspot_voucher
#     hotspot_package = HotspotPackage.find_by(name: params[:package])
#       if @hotspot_voucher.update(
#         package: params[:package],
#         shared_users: params[:shared_users],
#         phone: params[:phone],
#         hotspot_package_id: hotspot_package.id

#       )
#       ActivtyLog.create(action: 'update', ip: request.remote_ip,
#  description: "Updated hotspot voucher #{@hotspot_voucher.voucher}",
#           user_agent: request.user_agent, user: current_user.username || current_user.email,
#            date: Time.current)

#           create_voucher_radcheck(@hotspot_voucher.voucher, @hotspot_voucher.package,
#            @hotspot_voucher.shared_users, @hotspot_voucher.account_id)

#         render json: @hotspot_voucher, status: :ok
#       else
#         render json: @hotspot_voucher.errors, status: :unprocessable_entity 
      
#     end
    
#   end






#   def destroy
#   @hotspot_voucher = set_hotspot_voucher

#   if @hotspot_voucher.nil?
#     return render json: { error: "Hotspot voucher not found" }, status: :not_found
#   end

#   use_radius = router_uses_radius?

#   if use_radius
#     ActiveRecord::Base.transaction do
#       RadCheck.where(username: @hotspot_voucher.voucher).destroy_all
#       RadUserGroup.where(username: @hotspot_voucher.voucher).destroy_all
#       RadGroupCheck.where(groupname: @hotspot_voucher.voucher).destroy_all
#       @hotspot_voucher.destroy!
#     end

#     ActivtyLog.create(action: 'delete', ip: request.remote_ip,
#       description: "Deleted hotspot voucher #{@hotspot_voucher.voucher}",
#       user_agent: request.user_agent, user: current_user.username || current_user.email,
#       date: Time.current)

#     render json: { message: "Hotspot voucher deleted successfully" }, status: :ok
#   else
#     mikrotik_result = delete_voucher_natively(@hotspot_voucher)

#     ActiveRecord::Base.transaction do
#       @hotspot_voucher.destroy!
#     end

#     ActivtyLog.create(action: 'delete', ip: request.remote_ip,
#       description: "Deleted hotspot voucher #{@hotspot_voucher.voucher}",
#       user_agent: request.user_agent, user: current_user.username || current_user.email,
#       date: Time.current)

#     if mikrotik_result[:success]
#       render json: { message: "Hotspot voucher deleted successfully" }, status: :ok
#     else
#       Rails.logger.info "Voucher #{@hotspot_voucher.voucher} deleted locally but MikroTik cleanup failed: #{mikrotik_result[:error]}"
#       render json: {
#         message: "Hotspot voucher deleted successfully, but could not remove it from the router",
#         mikrotik_error: mikrotik_result[:error]
#       }, status: :ok
#     end
#   end
# rescue => e
#   render json: { error: "Failed to delete voucher: #{e.message}" }, status: :unprocessable_entity
# end

 


# def sync_to_mikrotik
#   @hotspot_voucher = HotspotVoucher.find_by(id: params[:id])
#   return render json: { error: 'Voucher not found' }, status: :not_found unless @hotspot_voucher

#   sync_voucher_natively(@hotspot_voucher)
#   render json: @hotspot_voucher
# rescue => e
#   render json: { error: "Sync failed: #{e.message}" }, status: :unprocessable_entity
# end




# def bulk_sync_to_mikrotik
#   ids = params[:ids] || params.dig(:hotspot_voucher, :ids) || []
#   return render json: { error: 'No vouchers selected' }, status: :unprocessable_entity if ids.empty?

#   HotspotVoucher.where(id: ids, account_id: ActsAsTenant.current_tenant.id)
#                 .update_all(sync_status: 'syncing', sync_error: nil)

#   HotspotVoucherBulkSyncJob.perform_later(ActsAsTenant.current_tenant.id, ids)

#   render json: { message: "Sync dispatched", queued: ids.size }, status: :accepted
# rescue => e
#   render json: { error: "Bulk sync failed: #{e.message}" }, status: :unprocessable_entity
# end

# # def login_with_hotspot_voucher

  

# # Rails.logger.info "voucher ip#{params[:ip]}"
  
# #   return render json: { error: 'voucher is required' }, status: :bad_request unless params[:voucher].present?

# #   # Get client IP
# #   client_ip = request.remote_ip

# #  host = request.headers['X-Subdomain']
# #  account = Account.find_by(subdomain: host)

# #   # Find the voucher in the database
# #   @hotspot_voucher = HotspotVoucher.find_by(voucher: params[:voucher])
# #   return render json: { error: 'Invalid voucher' }, status: :not_found unless @hotspot_voucher


# #       if @hotspot_voucher.expiration.present? && @hotspot_voucher.expiration < Time.current
# #       return render json: { error: 'Voucher expired' }, status: :forbidden
# #     end

# #   active_sessions = get_active_sessions(params[:voucher])
# # @shared_users = HotspotPackage.find_by(name: @hotspot_voucher.package).shared_users.to_i

  
# #   if active_sessions.any?
# #     active_voucher_sessions = active_sessions.select { |session| session.include?(params[:voucher]) }
  
# #     if active_voucher_sessions.count >= @shared_users
# #       return render json: { error: "Voucher is already used by another user, the maximum number of allowed device => #{@shared_users}" }, status: :forbidden
# #     end
# #   end
  
 
# #       nas_routers = NasRouter.where(account_id: account.id)

# #       nas_routers.each do |nas_router|
        
# #     router_ip_address = nas_router.ip_address
# #     router_password = nas_router.password
# #     router_username = nas_router.username


# #   command = "/ip hotspot active login user=#{params[:voucher]} password=#{params[:voucher]} ip=#{params[:ip]}"

# #   begin
# #     Net::SSH.start(router_ip_address,  router_username, password: router_password, verify_host_key: :never) do |ssh|
# #       output = ssh.exec!(command)
# #       if output.include?('failure')
# #         return render json: { error: "Login failed: #{output}" }, status: :unauthorized
# #       else
# #         @hotspot_voucher.update(status: 'used')
# #         return render json: {
# #           message: 'Connected successfully',
# #           device_ip: params[:ip],
# #           response: output,
# #            username:  @hotspot_voucher.voucher,
# #         expiration:  @hotspot_voucher.expiration.strftime("%B %d, %Y at %I:%M %p"),
# #         package:  @hotspot_voucher.package
# #         }, status: :ok
# #       end
# #     end
# #   rescue Net::SSH::AuthenticationFailed
# #     render json: { error: 'SSH authentication failed' }, status: :unauthorized
# #   rescue StandardError => e
# #     render json: { error: "Failed to log in device", message: e.message }, status: :internal_server_error
# #   end
# #       end

        
# # end
 


# def login_with_hotspot_voucher
#   return render json: { error: 'voucher is required' }, status: :bad_request unless params[:voucher].present?

#   @hotspot_voucher = HotspotVoucher.find_by(voucher: params[:voucher])
#   return render json: { error: 'Invalid voucher or username' }, status: :not_found unless @hotspot_voucher

#   if @hotspot_voucher.expiration.present? && @hotspot_voucher.expiration < Time.current
#     return render json: { error: 'Voucher Or Username expired' }, status: :forbidden
#   end

#   enable_compensation = ActsAsTenant.current_tenant&.hotspot_customization&.enable_compensation

#   if @hotspot_voucher.expiration.nil?
#     if enable_compensation
#       create_voucher_radcheck_compensation(@hotspot_voucher.voucher,
#         @hotspot_voucher.package,
#         @hotspot_voucher.account_id)
#     end
#   end

#   if @hotspot_voucher.expiration.nil?
#     create_voucher_radcheck(@hotspot_voucher.voucher,
#       @hotspot_voucher.package,
#       @hotspot_voucher.account_id)
#   end

#   # get_active_sessions now already filters to just this voucher's sessions,
#   # and returns an array of hashes, e.g. [{"user"=>"ABC123", ".id"=>"*1A", ...}]
#   active_sessions = get_active_sessions(params[:voucher])
#   package = HotspotPackage.find_by(name: @hotspot_voucher.package)

#   shared_users = package&.shared_users.to_i

#   # no more .select { |s| s.include?(...) } needed — get_active_sessions
#   # already returns only sessions matching this voucher
#   if active_sessions.count >= shared_users
#     return render json: {
#       error: "Voucher already used. Max devices allowed: #{shared_users}"
#     }, status: :forbidden
#   end

#   nas_routers = NasRouter.where(account_id: @hotspot_voucher.account_id)

#   nas_routers.each do |router|
#     begin
#       response = RestClient::Request.execute(
#         method: :post,
#         url: "http://#{router.ip_address}/rest/ip/hotspot/active/login",
#         user: router.username,
#         password: router.password,
#         payload: {
#           ip: params[:ip],
#           user: params[:voucher],
#           password: params[:voucher]
#         }.to_json,
#         headers: {
#           content_type: :json,
#           accept: :json
#         },
#         timeout: 5,       # ← added: stop hanging on a slow/dead router
#         open_timeout: 3   # ← added: stop hanging on an unreachable router
#       )

#       if response.code == 200
#         @hotspot_voucher.update!(status: 'used', last_logged_in: Time.now,
#           ip: params[:ip], mac: params[:mac], used_voucher: true,
#           login_by: 'Voucher Code'
#         )

#         if @hotspot_voucher.expiration.nil?
#           if enable_compensation
#             calculate_expiration_login_with_voucher_compensation(package, @hotspot_voucher,
#               @hotspot_voucher.account_id)
#           end
#         end

#         if @hotspot_voucher.expiration.nil?
#           calculate_expiration_login_with_voucher(package, @hotspot_voucher,
#             @hotspot_voucher.account_id)
#         end

#         return render json: {
#           message: 'Connected successfully',
#           device_ip: params[:ip],
#           username: @hotspot_voucher.voucher,
#           expiration: @hotspot_voucher.expiration&.strftime("%B %d, %Y at %I:%M %p"),
#           package: @hotspot_voucher.package
#         }, status: :ok
#       end

#     rescue RestClient::Unauthorized
#       Rails.logger.info "REST auth failed for router #{router.ip_address}"
#       next

#     rescue RestClient::ExceptionWithResponse => e
#       Rails.logger.info "MikroTik REST error (#{router.ip_address}): #{e.response}"
#       next

#     rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
#       Rails.logger.info "Router #{router.ip_address} timed out during login"
#       next

#     rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
#       Rails.logger.info "Router #{router.ip_address} unreachable: #{e.message}"
#       next

#     rescue StandardError => e
#       Rails.logger.info "REST login error: #{e.message}"
#       next
#     end
#   end

#   return render json: { error: 'Failed to connect please try again' }, status: :unprocessable_entity
# end









  
#   private
#     def set_hotspot_voucher
#       @hotspot_voucher = HotspotVoucher.find_by_id(params[:id])
#     end




# def calculate_expiration_login(package, voucher_created, account_id)
#    hotspot_package = HotspotPackage.find_by(name: package, 
#   account_id: account_id)

#   return render json: { error: 'Package not found' }, status: :not_found unless hotspot_package
  
#   # Calculate expiration
#   expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
#     case hotspot_package.validity_period_units.downcase
#     when 'days'
#       Time.current + hotspot_package.validity.days
#     when 'hours'
#       Time.current + hotspot_package.validity.hours
#     when 'minutes'
#       Time.current + hotspot_package.validity.minutes
#     else
#       nil
#     end


    

#   # elsif hotspot_package.valid_until.present? && hotspot_package.valid_from.present?
#   #   hotspot_package.valid_until
#   else
#     nil
#   end

#   # Update status only if expiration is present
#   if expiration_time.present?
#     voucher_created.update(expiration: 
#     expiration_time&.strftime("%B %d, %Y at %I:%M %p"),
#     # status: 'active'
#     )
#   end

#   # Return both expiration and status
#   {
#     expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),
#     # status: 'active'
#   }
# end








# def calculate_expiration_login_with_voucher(hotspot_package, 
#   voucher_created,
#    account_id)
#   #  hotspot_package = HotspotPackage.find_by(name: package, 
#   # account_id: account_id)

#   return render json: { error: 'Package not found' }, status: :not_found unless hotspot_package
  
#   # Calculate expiration
#   expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
#     case hotspot_package.validity_period_units.downcase
#     when 'days'
#       Time.current + hotspot_package.validity.days
#     when 'hours'
#       Time.current + hotspot_package.validity.hours
#     when 'minutes'
#       Time.current + hotspot_package.validity.minutes
#     else
#       nil
#     end


    

#   # elsif hotspot_package.valid_until.present? && hotspot_package.valid_from.present?
#   #   hotspot_package.valid_until
#   else
#     nil
#   end

#   # Update status only if expiration is present
#   if expiration_time.present?
#     voucher_created.update(expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),)
#   end

 
  
# end



# def calculate_expiration_login_with_voucher(hotspot_package,
#    voucher_created,
#    account_id)
#   #  hotspot_package = HotspotPackage.find_by(name: package, 
#   # account_id: account_id)
# return unless hotspot_package
#   # Calculate expiration
#   expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
#     case hotspot_package.validity_period_units.downcase
#     when 'days'
#       Time.current + hotspot_package.validity.days
#     when 'hours'
#       Time.current + hotspot_package.validity.hours
#     when 'minutes'
#       Time.current + hotspot_package.validity.minutes
#     else
#       nil
#     end


    

#   # elsif hotspot_package.valid_until.present? && hotspot_package.valid_from.present?
#   #   hotspot_package.valid_until
#   else
#     nil
#   end

#   # Update status only if expiration is present
#   if expiration_time.present?
#     voucher_created.update(expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),)
#   end

#   # Return both expiration and status
#   {
#     expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),
#   }
# end







# def calculate_expiration_login_with_voucher_compensation(hotspot_package,
#    voucher_created,
#    account_id)
#   #  hotspot_package = HotspotPackage.find_by(name: package, 
#   # account_id: account_id)

#   return render json: { error: 'Package not found' }, status: :not_found unless hotspot_package
  
#   # Calculate expiration
#   expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
#     case hotspot_package.validity_period_units.downcase
#     when 'days'
#       Time.current + hotspot_package.validity.days
#     when 'hours'
#       Time.current + hotspot_package.validity.hours
#     when 'minutes'
#       Time.current + hotspot_package.validity.minutes
#     else
#       nil
#     end


#   # elsif hotspot_package.valid_until.present? && hotspot_package.valid_from.present?
#   #   hotspot_package.valid_until
#   else
#     nil
#   end
# tenant = Account.find_by(id: account_id)
# extra_time = compensation_duration(tenant)
#   final_expiration = expiration_time + extra_time


#   # Update status only if expiration is present
#   if expiration_time.present?
#     voucher_created.update(expiration: final_expiration&.strftime("%B %d, %Y at %I:%M %p"),)
#   end

 
# end





# def calculate_expiration(package, voucher_created, account_id)
#   hotspot_package = HotspotPackage.find_by(name: package, 
#   account_id: account_id)

#   return render json: { error: 'Package not found' }, status: :not_found unless hotspot_package
  
#   # Calculate expiration
#   expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
#     case hotspot_package.validity_period_units.downcase
#     when 'days'
#       Time.current + hotspot_package.validity.days
#     when 'hours'
#       Time.current + hotspot_package.validity.hours
#     when 'minutes'
#       Time.current + hotspot_package.validity.minutes
#     else
#       nil
#     end


    

#   # elsif hotspot_package.valid_until.present? && hotspot_package.valid_from.present?
#   #   hotspot_package.valid_until
#   else
#     nil
#   end

#   # Update status only if expiration is present
#   if expiration_time.present?
#     voucher_created.update(status: 'active',  expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),)
#   else
#     status = "unknown" # Handle cases with no expiration logic
#   end

#   # Return both expiration and status
#   {
#     expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),
#     status: status
#   }
# end










# def calculate_expiration_send_to_customer(package, account_id)
#   hotspot_package = HotspotPackage.find_by(name: package, account_id: account_id)

# return render json: { error: 'Package not found' }, status: :not_found unless hotspot_package

# # Calculate expiration
# expiration_time = if hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
#   case hotspot_package.validity_period_units.downcase
#   when 'days'
#     Time.current + hotspot_package.validity.days
#   when 'hours'
#     Time.current + hotspot_package.validity.hours
#   when 'minutes'
#     Time.current + hotspot_package.validity.minutes
#   else
#     nil
#   end

#   # elsif hotspot_package.valid_until.present? && hotspot_package.valid_from.present?
#   #   hotspot_package.valid_until


#   else
#     nil
#   end

  
#     expiration_time&.strftime("%B %d, %Y at %I:%M %p")
  
# end





# # selected_provider

#     # def generate_voucher_code
#     #   voucher_type = HotspotSetting.find_by(voucher_type: 'Mixed').voucher_type
#     #   loop do
#     #     code = SecureRandom.hex(4).upcase 
#     #     break code unless HotspotVoucher.exists?(voucher: code)
#     #   end
#     # end

# def generate_voucher_code
#   hotspot_setting = ActsAsTenant.current_tenant&.hotspot_setting
#   voucher_type = hotspot_setting&.voucher_type || 'Mixed'

#   prefix = hotspot_setting&.voucher_prefix.to_s.strip
#   # code_length is the length of the RANDOM portion the user configured
#   # (4-16, enforced by HotspotSettingsController#normalized_code_length).
#   # The prefix is prepended on top of that.
#   code_length = hotspot_setting&.code_length.to_i
#   code_length = 8 if code_length <= 0

#   # .chars turns the string into an array of single-char strings so
#   # .sample (an Array method) actually works — calling .sample directly
#   # on a String raised NoMethodError.
#   numeric_chars = '0123456789'.chars
#   alpha_chars   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.chars
#   mixed_chars   = numeric_chars + alpha_chars

#   loop do
#     random_part =
#       case voucher_type
#       when 'Numeric'
#         Array.new(code_length) { numeric_chars.sample }.join

#       when 'Words'
#         words = %w[
#           SKY NET FAST WIFI DATA ZONE LINK CLOUD
#           SPEED HOT SPOT CONNECT
#         ]
#         raw = "#{words.sample}#{words.sample}"
#         if raw.length >= code_length
#           raw[0, code_length]
#         else
#           raw + Array.new(code_length - raw.length) { alpha_chars.sample }.join
#         end

#       when 'Mixed'
#         Array.new(code_length) { mixed_chars.sample }.join

#       else
#         Array.new(code_length) { mixed_chars.sample }.join
#       end

#     code = prefix.present? ? "#{prefix}#{random_part}" : random_part

#     break code unless HotspotVoucher.exists?(voucher: code)
#   end
# end






#     # Only allow a list of trusted parameters through.
#     def hotspot_voucher_params
#       params.permit(:voucher, :status, :expiration, :speed_limit, :phone,
#       :package)
#     end










# def get_user_manager_user_id(hotspot_voucher)
#   router_name = params[:router_name]
#   nas_router = NasRouter.find_by(name: router_name)
#   if nas_router
#     router_ip_address = nas_router.ip_address
#       router_password = nas_router.password
#      router_username = nas_router.username
  
#   else
  
#     render json: { error: 'NAS router not found' }, status: :not_found
#     return
#   end



#   request_body = {
   
    
#     "name": "#{hotspot_voucher}",

   
# }
#  request_body["shared-users"] = params[:shared_users] if params[:shared_users].present?
# uri = URI("http://#{router_ip_address}/rest/user-manager/user/add")
# request = Net::HTTP::Post.new(uri)
# request.basic_auth router_username, router_password
# request['Content-Type'] = 'application/json'
# request.body = request_body.to_json

# response = Net::HTTP.start(uri.hostname, uri.port) do |http|
#   http.request(request)
# end

# if response.is_a?(Net::HTTPSuccess)
#   data = JSON.parse(response.body)
#         return data['ret']

# else
#   puts "Failed to fetch user manager user from mikrotik  : #{response.code} - #{response.message}"
# end

  
# end




# def get_user_profile_id_from_mikrotik(hotspot_voucher)
#   router_name = params[:router_name]
#   nas_router = NasRouter.find_by(name: router_name)
#   if nas_router
#     router_ip_address = nas_router.ip_address
#       router_password = nas_router.password
#      router_username = nas_router.username
  
#   else
  
#     render json: { error: 'NAS router not found' }, status: :not_found
#     return
#   end


#   request_body = {
   
    
#   # "user": "#{hotspot_voucher.voucher}",
  
#       "user": "#{hotspot_voucher}",
#     "profile": "#{params[:package]}",
 
# }
# Rails.logger.info "Request body: #{request_body}"

# uri = URI("http://#{router_ip_address}/rest/user-manager/user-profile/add")
# request = Net::HTTP::Post.new(uri)
# request.basic_auth router_username, router_password
# request['Content-Type'] = 'application/json'
# request.body = request_body.to_json

# response = Net::HTTP.start(uri.hostname, uri.port) do |http|
# http.request(request)
# end

# if response.is_a?(Net::HTTPSuccess)
# data = JSON.parse(response.body)
#       return data['ret']

# else
# puts "Failed to fetch user manager user profile id from mikrotik : #{response.code} - #{response.message}"
# end



#     end


        







# private





# def sync_voucher_natively(voucher)
#   package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
#   return voucher.update(sync_status: 'failed', sync_error: 'Package not found') unless package

#   nas = NasRouter.find_by(name: package.nas_router, account_id: voucher.account_id)
#   return voucher.update(sync_status: 'failed', sync_error: 'No router specified or router not found') unless nas

#   RestClient::Request.execute(
#     method: :put,
#     url: "http://#{nas.ip_address}/rest/ip/hotspot/user",
#     user: nas.username.to_s, password: nas.password.to_s,
#     payload: { name: voucher.voucher, password: voucher.voucher, profile: package.name }.to_json,
#     headers: { content_type: :json },
#     timeout: 10,
#     open_timeout: 5
#   )
#   voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)

# rescue RestClient::ExceptionWithResponse => e
#   voucher.update(sync_status: 'failed', sync_error: mikrotik_error_message(e))
# rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
#   voucher.update(sync_status: 'failed', sync_error: "Router #{nas.ip_address} timed out")
# rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
#   voucher.update(sync_status: 'failed', sync_error: "Router unreachable: #{e.message}")
# rescue => e
#   voucher.update(sync_status: 'failed', sync_error: e.message)
# end

# def sync_voucher_natively_realtime_expiration(voucher)
#   package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
#   return voucher.update(sync_status: 'failed', sync_error: 'Package not found') unless package

#   nas = NasRouter.find_by(name: package.nas_router)
#   return voucher.update(sync_status: 'failed', sync_error: 'No router specified or router not found') unless nas

#   RestClient::Request.execute(
#     method: :put,
#     url: "http://#{nas.ip_address}/rest/ip/hotspot/user",
#     user: nas.username.to_s, password: nas.password.to_s,
#     payload: { name: voucher.voucher, password: voucher.voucher,
#       profile: package.name, "limit-uptime": validity_for_mikrotik(package) }.to_json,
#     headers: { content_type: :json },
#     timeout: 10,
#     open_timeout: 5
#   )
#   voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)

# rescue RestClient::ExceptionWithResponse => e
#   voucher.update(sync_status: 'failed', sync_error: mikrotik_error_message(e))
# rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
#   voucher.update(sync_status: 'failed', sync_error: "Router #{nas.ip_address} timed out")
# rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
#   voucher.update(sync_status: 'failed', sync_error: "Router unreachable: #{e.message}")
# rescue => e
#   voucher.update(sync_status: 'failed', sync_error: e.message)
# end

# def mikrotik_error_message(e)
#   return e.message unless e.response
#   body = e.response.body.to_s
#   parsed = JSON.parse(body) rescue nil
#   return body.presence || e.message unless parsed
#   parsed['detail'] || parsed['message'] || parsed['error'] || body
# end
















# def validity_for_mikrotik(pkg)
#   case pkg.validity_period_units
#   when "minutes"
#     "#{pkg.validity}m"
#   when "hours"
#     "#{pkg.validity}h"
#   when "days"
#     "#{pkg.validity}d"
#   when "weeks"
#     "#{pkg.validity}w"
#   else
#     "0s"
#   end
# end


# def delete_voucher_natively(voucher)
#   package = HotspotPackage.find_by(
#     name: voucher.package,
#     account_id: voucher.account_id
#   )

#   nas = NasRouter.find_by(name: package&.nas_router)

#   return {
#     success: false,
#     error: "No router specified or router not found"
#   } unless nas

#   begin
#     base_url = "http://#{nas.ip_address}/rest/ip/hotspot/user"

#     # ---------------------------------------------------------
#     # 1. Disconnect active session first
#     # ---------------------------------------------------------
#     active_sessions = get_active_sessions(voucher.voucher)

#     active_sessions.to_a.each do |session|
#       session_id = session[".id"]
#       next unless session_id.present?

#       encoded_session_id =
#         URI::DEFAULT_PARSER.escape(session_id.to_s)

#       RestClient::Request.execute(
#         method: :delete,
#         url: "http://#{nas.ip_address}/rest/ip/hotspot/active/#{encoded_session_id}",
#         user: nas.username.to_s,
#         password: nas.password.to_s,
#         timeout: 5,
#         open_timeout: 3
#       )
#     end

#     # ---------------------------------------------------------
#     # 2. Get all hotspot users
#     # ---------------------------------------------------------
#     response = RestClient::Request.execute(
#       method: :get,
#       url: base_url,
#       user: nas.username.to_s,
#       password: nas.password.to_s,
#       headers: {
#         accept: :json
#       },
#       timeout: 10,
#       open_timeout: 5
#     )

#     users = JSON.parse(response.body)

#     # ---------------------------------------------------------
#     # 3. Find the MikroTik user by voucher name
#     # ---------------------------------------------------------
#     hotspot_user = users.find do |user|
#       user["name"].to_s == voucher.voucher.to_s
#     end

#     # User doesn't exist on MikroTik anymore
#     return { success: true } unless hotspot_user

#     # ---------------------------------------------------------
#     # 4. Get MikroTik internal resource ID
#     # ---------------------------------------------------------
#     user_id = hotspot_user[".id"]

#     unless user_id.present?
#       return {
#         success: false,
#         error: "MikroTik hotspot user found but has no .id"
#       }
#     end

#     Rails.logger.info(
#       "Deleting MikroTik hotspot user '#{voucher.voucher}' with .id=#{user_id}"
#     )

#     # ---------------------------------------------------------
#     # 5. Delete using MikroTik .id
#     # ---------------------------------------------------------
#     encoded_user_id =
#       URI::DEFAULT_PARSER.escape(user_id.to_s)

#     RestClient::Request.execute(
#       method: :delete,
#       url: "#{base_url}/#{encoded_user_id}",
#       user: nas.username.to_s,
#       password: nas.password.to_s,
#       headers: {
#         content_type: :json
#       },
#       timeout: 5,
#       open_timeout: 3
#     )

#     { success: true }

#   rescue RestClient::NotFound
#     # Already deleted from MikroTik
#     { success: true }

#   rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
#     {
#       success: false,
#       error: "Router #{nas.ip_address} timed out"
#     }

#   rescue Errno::ECONNREFUSED,
#          Errno::EHOSTUNREACH,
#          SocketError => e
#     {
#       success: false,
#       error: "Router #{nas.ip_address} unreachable: #{e.message}"
#     }

#   rescue RestClient::ExceptionWithResponse => e
#     {
#       success: false,
#       error: e.response&.body.presence || e.message
#     }

#   rescue => e
#     {
#       success: false,
#       error: e.message
#     }
#   end
# end

# def router_uses_radius?
#   return true unless ActsAsTenant.current_tenant
#   setting = NasSetting.find_by(account_id: ActsAsTenant.current_tenant.id )
#   setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
# end



# def router_uses_radius_payment(account_id)
#   setting = NasSetting.find_by(account_id: account_id)
#   setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
# end




# def mikrotik_add_binding_direct(binding, nas)
#   require 'net/ssh'
#   mac = binding.mac.upcase.gsub('-', ':')
#   cmd = "/ip hotspot ip-binding add mac-address=\"#{mac}\" type=bypassed server=hotspot1"
#   cmd += " comment=\"#{binding.name}\"" if binding.name.present?

#   Net::SSH.start(nas.ip_address, nas.username,
#     password: nas.password.to_s, verify_host_key: :never,
#     non_interactive: true, timeout: 15
#   ) { |ssh| ssh.exec!(cmd) }
# end



# def mikrotik_add_queue_direct(binding, package, nas)
#   return unless binding.ip.present? && package.upload_limit.present?
#   require 'net/ssh'

#   queue_name = "binding_#{binding.mac.upcase.gsub(':', '')}"
#   cmd = "/queue simple add name=\"#{queue_name}\" target=\"#{binding.ip}\" " \
#         "max-limit=\"#{package.upload_limit}M/#{package.download_limit}M\" " \
#         "comment=\"device_binding_#{binding.id}\""

#   Net::SSH.start(nas.ip_address, nas.username,
#     password: nas.password.to_s, verify_host_key: :never,
#     non_interactive: true, timeout: 15
#   ) { |ssh| ssh.exec!(cmd) }
# end







#       def compensation_duration(tenant)
#   customization = tenant.hotspot_customization

#   return 0 unless customization&.enable_compensation

#   if customization.compensation_minutes.present?
#     customization.compensation_minutes.to_i.minutes
#   elsif customization.compensation_hours.to_i.present?
#     customization.compensation_hours.hours
#   else
#     0
#   end
# end




#       def format_bytes(bytes)
#       units = ['B', 'KB', 'MB', 'GB', 'TB']
#       return '0 B' if bytes.zero?
    
#       exp = (Math.log(bytes) / Math.log(1024)).to_i
#       size = bytes / (1024.0**exp)
#       "%.2f #{units[exp]}" % size
    
    
#   end




#   def format_uptime(seconds)
#   return '0s' if seconds.nil?

#   mm, ss = seconds.divmod(60)
#   hh, mm = mm.divmod(60)
#   dd, hh = hh.divmod(24)

#   parts = []
#   parts << "#{dd}d" if dd > 0
#   parts << "#{hh}h" if hh > 0
#   parts << "#{mm}m" if mm > 0
#   parts << "#{ss}s"
#   parts.join(' ')
#     end





#     def send_voucher(phone_number, voucher_code, shared_users, company_name, current_user)
#   voucher = HotspotVoucher.find_by(voucher: voucher_code)
#   voucher.update(sms_sent: true)

#   data = build_voucher_sms_data(voucher, phone_number, shared_users, company_name)
#   original_message = render_hotspot_sms('single', data)   # ← was the hardcoded string

#   api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
#   api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
#   sender_id = "SMS_TEST"

#   uri = URI("https://api.smsleopard.com/v1/sms/send")
#   params = {
#     username: api_key, password: api_secret,
#     message: original_message, destination: phone_number, source: sender_id
#   }
#   uri.query = URI.encode_www_form(params)
#   response = Net::HTTP.get_response(uri)

#   if response.is_a?(Net::HTTPSuccess)
#     sms_data = JSON.parse(response.body)
#     sms_recipient = sms_data['recipients'][0]['number']
#     sms_status = sms_data['recipients'][0]['status']

#     SystemAdminSm.create!(
#       user: sms_recipient, message: original_message, status: sms_status,
#       date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
#       system_user: current_user.username, sms_provider: 'SMS leopard'
#     )
#   else
#     Rails.logger.info "Failed to send message: #{response.body}"
#   end
# end

             


#            def send_voucher_text_sms(phone_number, voucher_code,
#              shared_users, company_name, current_user
#             )
#   # Was previously receiving the voucher code in a param literally named
#   # `voucher`, but the body referenced an undefined `voucher_code` — a
#   # guaranteed NameError on every call. Renamed the param to match, and
#   # look up the actual HotspotVoucher record before using it, same as
#   # the SMS Leopard sender above (build_voucher_sms_data needs the
#   # record, not the bare code string).
#   hotspot_voucher = HotspotVoucher.find_by(voucher: voucher_code)
#   unless hotspot_voucher
#     Rails.logger.info "send_voucher_text_sms: voucher #{voucher_code} not found"
#     return
#   end


#   hotspot_voucher.update(sms_sent: true)

#   sms_setting = SmsSetting.find_by(sms_provider: 'TextSms')

#   # if sms_setting.nil?
#   #   render json: { error: "SMS provider not found" }, status: :not_found
#   #   return
#   # end

#   api_key = sms_setting&.api_key
#   partnerID = sms_setting&.partnerID 
#    shortcode = sms_setting.sender_id

#   sms_template = ActsAsTenant.current_tenant.sms_template
#   send_voucher_template = sms_template&.send_voucher_template





#   Rails.logger.info "API KEY: #{api_key.inspect}"
# Rails.logger.info "PARTNER ID: #{partnerID.inspect}"
# Rails.logger.info "SHORTCODE: #{shortcode.inspect}"
# Rails.logger.info "PHONE: #{phone_number.inspect}"

#   # original_message = if sms_template
#   #   MessageTemplate.interpolate(send_voucher_template, { voucher_code: voucher_code })
#   # else
#   #   "Your voucher code: #{voucher_code} for #{shared_users} devices. This code is valid until #{voucher_expiration}.
#   #    Enjoy your browsing"
#   # end

#     # original_message = "Your voucher code is: #{voucher_code}. This code is valid until #{voucher_expiration}.


#     data = build_voucher_sms_data(hotspot_voucher, phone_number, shared_users, company_name)
# original_message = render_hotspot_sms('single', data)

#   uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
#   params = {
#     apikey: api_key,
#     message: original_message,
#     mobile: phone_number,
#     partnerID: partnerID,
#     shortcode: shortcode
#   }

# Rails.logger.info "MESSAGE: #{original_message}"

#   uri.query = URI.encode_www_form(params)

#   response = Net::HTTP.get_response(uri)

#   if response.is_a?(Net::HTTPSuccess)
#     sms_data = JSON.parse(response.body)

#       sms_recipient = sms_data['responses'][0]['mobile']
#       sms_status = sms_data['responses'][0]['response-description']

#        Rails.logger.info  "Recipient: #{sms_recipient}, Status: #{sms_status}"

#       # Save the message and response details in your database
     
#  SystemAdminSm.create!(
#         user: sms_recipient,
#         message: original_message,
#         status: sms_status,
#         date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
#         system_user: current_user.username,
#         sms_provider: 'Text Sms')
    
#       # render json: { error: "Failed to send message: #{sms_data['responses'][0]['response-description']}" }
#        Rails.logger.info "sent message: #{sms_data['responses'][0]['response-description']}"
       
    
#   else
#     puts "Failed to send message: #{response.body}"
#     # render json: { error: "Failed to send message: #{response.body}" }
#   end
# end








#  def send_voucher_talksasa(phone_number, voucher_code,
#                           shared_users, company_name, current_user)

#                           formatted_phone_number = "254#{phone_number.gsub(/\A0/, '')}"
#   # Same fix as send_voucher_text_sms above: the param was named `voucher`
#   # while the body referenced the undefined `voucher_code` — renamed the
#   # param so the existing lookup below actually resolves.
#   HotspotVoucher.find_by(voucher: voucher_code)&.update(sms_sent: true)
#   voucher = HotspotVoucher.find_by(voucher: voucher_code)

#   sms_setting = SmsSetting.find_by(sms_provider: 'Talk Sasa')

#   api_key  = sms_setting&.api_key
#   sender_id = sms_setting&.sender_id

#   sms_template = ActsAsTenant.current_tenant.sms_template
#   send_voucher_template = sms_template&.send_voucher_template
# data = build_voucher_sms_data(voucher, phone_number, shared_users, company_name)
# original_message = render_hotspot_sms('single', data)


#   uri = URI.parse("https://bulksms.talksasa.com/api/v3/sms/send")

#   http = Net::HTTP.new(uri.host, uri.port)
#   http.use_ssl = true

#   request = Net::HTTP::Post.new(uri.request_uri)

#   request["Authorization"] = "Bearer #{api_key}"
#   request["Content-Type"] = "application/json"
#   request["Accept"] = "application/json"

#   request.body = {
#     recipient: formatted_phone_number,
#     sender_id: sender_id,
#     type: "plain",
#     message: original_message
#   }.to_json

#   response = http.request(request)

#   Rails.logger.info "TalkSasa Response: #{response.body}"

#   if response.is_a?(Net::HTTPSuccess)
#     sms_data = JSON.parse(response.body)

#     first_response = sms_data['responses']&.first

#     sms_recipient = first_response&.dig('mobile')
#     sms_status    = sms_data['status']

#     Rails.logger.info "sms data =>: #{sms_data}, Status: #{sms_status}"

#     SystemAdminSm.create!(
#       user: phone_number,
#       message: original_message,
#       status: sms_status,
#       date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
#       system_user: current_user.username,
#       sms_provider: 'Talk Sasa'
#     )

#     Rails.logger.info "Sent message successfully with talk sasa"
#   else
#     Rails.logger.info "Failed to send SMS: #{response.code} - #{response.body}"
#     SystemAdminSm.create!(
#       user: phone_number,
#       message: original_message,
#       status: sms_status,
#       date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
#       system_user: current_user.username,
#       sms_provider: 'Talk Sasa'
#     )
#   end
# end





# def mikrotik_add_queue_for_tv_plan(binding, tv_plan, nas)
#   return unless binding.ip.present? && tv_plan&.upload_limit.present?
#   require 'net/ssh'

#   queue_name = "binding_#{binding.mac.upcase.gsub(':', '')}"
#   cmd = "/queue simple add name=\"#{queue_name}\" target=\"#{binding.ip}\" " \
#         "max-limit=\"#{tv_plan.upload_limit}M/#{tv_plan.download_limit}M\" " \
#         "comment=\"tv_plan_#{binding.id}\""

#   Net::SSH.start(nas.ip_address, nas.username,
#     password: nas.password.to_s, verify_host_key: :never,
#     non_interactive: true, timeout: 15
#   ) { |ssh| ssh.exec!(cmd) }
# end














# def tv_plan_expiration(tv_plan)
#   seconds =
#     case tv_plan.validity_period_units.to_s.downcase
#     when 'minutes' then tv_plan.validity.to_i.minutes
#     when 'hours'   then tv_plan.validity.to_i.hours
#     when 'days'    then tv_plan.validity.to_i.days
#     else 0.seconds
#     end

#   (Time.current + seconds).strftime("%Y-%m-%d %H:%M:%S")
# end


# def get_active_sessions(voucher)
#   nas_routers = NasRouter.where(account_id: ActsAsTenant.current_tenant.id)
#   all_matching_sessions = []

#   nas_routers.each do |nas_router|
#     begin
#       response = RestClient::Request.execute(
#         method: :get,
#         url: "http://#{nas_router.ip_address}/rest/ip/hotspot/active",
#         user: nas_router.username,
#         password: nas_router.password,
#         timeout: 5,       # read timeout - how long to wait for a response
#         open_timeout: 3   # connection timeout - how long to wait to even connect
#       )

#       users = JSON.parse(response.body)
#       matching = users.select { |u| u["user"] == voucher }

#       if matching.any?
#         Rails.logger.info "Found #{matching.count} active session(s) for voucher #{voucher} on router #{nas_router.ip_address}"
#         all_matching_sessions.concat(matching)
#       end

#     rescue RestClient::Unauthorized
#       Rails.logger.error "REST auth failed for router #{nas_router.ip_address}"
#       next

#     rescue RestClient::ExceptionWithResponse => e
#       Rails.logger.error "MikroTik REST error on #{nas_router.ip_address}: #{e.response}"
#       next

#     rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
#       Rails.logger.error "Timed out reaching router #{nas_router.ip_address} for active sessions"
#       next

#     rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
#       Rails.logger.error "Router #{nas_router.ip_address} unreachable: #{e.message}"
#       next

#     rescue StandardError => e
#       Rails.logger.error "Failed to get active sessions from #{nas_router.ip_address}: #{e.message}"
#       next
#     end
#   end

#   all_matching_sessions
# end







# # private section, near the other sms senders

# def build_voucher_sms_data(voucher, phone_number, shared_users, company_name)
#   package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)

#   {
#     customer_phone: phone_number,
#     plan_name: package&.name,
#     voucher_code: voucher.voucher,
#     username: voucher.voucher,
#     password: voucher.voucher,
#     validity: voucher.expiration&.strftime("%B %d, %Y at %I:%M %p"),
#     price: package&.price,
#     company_name: company_name,
#     voucher_count: shared_users,
#     voucher_list: HotspotSmsTemplate.format_voucher_list(
#       [{ code: voucher.voucher, username: voucher.voucher, password: voucher.voucher }]
#     )
#   }
# end

# # group is 'single' because these methods send exactly one voucher code
# # to one phone number. If you later build a bulk "send N vouchers to one
# # number" flow, call render_hotspot_sms('multi', data) from there instead.
# def render_hotspot_sms(group, data)
#   template = HotspotSmsTemplate.active_for(ActsAsTenant.current_tenant.id, group)
#   return default_hotspot_sms_message(group, data) unless template

#   template.render(data)
# end

# def default_hotspot_sms_message(group, data)
#   if group == 'multi'
#     "Your voucher codes:\n#{data[:voucher_list]}\nValid for: #{data[:validity]}. Enjoy your browsing (FROM: #{data[:company_name]})"
#   else
#     "Your voucher code is: #{data[:voucher_code]}. Enjoy your browsing (FROM: #{data[:company_name]})"
#   end
# end






# def send_tv_plan_confirmation_sms(binding, tv_plan, session)
#   return unless session.phone_number.present?

#   data = {
#     customer_phone: session.phone_number,
#     device_name:    binding.name,
#     plan_name:      tv_plan&.name,
#     price:          tv_plan&.price,
#     validity:       binding.expiry&.to_s,
#     portal_url:     hotspot_portal_url(session.account_id),
#     company_name:   ActsAsTenant.current_tenant&.company_setting&.company_name
#   }

#   template = HotspotSmsTemplate.active_for(session.account_id, 'tv_plan_purchase')
#   message = template ? template.render(data) : default_tv_plan_sms(data)

#   provider = ActsAsTenant.current_tenant&.sms_provider_setting&.sms_provider
#   case provider
#   when 'SMS leopard'   then send_sms_leopard_raw(session.phone_number, message)
#   when 'TextSms'       then send_textsms_raw(session.phone_number, message)
#   when 'Talk Sasa'     then send_talksasa_raw(session.phone_number, message)
#   end
# rescue => e
#   Rails.logger.error "send_tv_plan_confirmation_sms failed: #{e.message}"
# end


# def default_tv_plan_sms(data)
#   "Payment received! Your #{data[:plan_name]} plan for #{data[:device_name]} is active until #{data[:validity]}. " \
#   "Manage devices: #{data[:portal_url]} (login with this phone number). — #{data[:company_name]}"
# end

# # Build the portal URL for the customer's tenant — adjust the default
# # platform domain / account->domain mapping to match how you already
# def hotspot_portal_url(account_id)
#   account = Account.find_by(id: account_id)
#   return nil unless account

#   platform_domain = account.respond_to?(:platform_domain) && account.platform_domain.present? ? account.platform_domain : 'aitechs.co.ke'
#   "https://#{account.subdomain}.#{platform_domain}/hotspot-customer-portal"
# end

# end


class HotspotVouchersController < ApplicationController
  include BroadcastsHotspotPayments

load_and_authorize_resource except: [:login_with_hotspot_voucher,
 :make_payment, :check_payment_status, :payment_and_conected_status,
 :login_with_receipt_number, :calculate_expiration_login_with_voucher,
 :create_voucher_radcheck, :receipt_number_status, :stk_push_status, :payment_reference_status

]
  # skip_before_action :set_tenant, only: [:check_payment_status]


  set_current_tenant_through_filter

  before_action :set_tenant, except: [:check_payment_status,
   :transaction_status_result]
  before_action :set_time_zone


  #  before_action :whitelist_mpesa_ips, only: [:check_payment_status]




def whitelist_mpesa_ips
    allowed_ips = [
      '196.201.214.200',
      '196.201.214.206',
      '196.201.213.114',
      '196.201.214.207',
      '196.201.214.208',
      '196.201.213.44',
      '196.201.212.127',
      '196.201.212.138',
      '196.201.212.129',
      '196.201.212.136',
      '196.201.212.74',
      '196.201.212.69'
    ]

    unless allowed_ips.include?(request.remote_ip)
      Rails.logger.info "Not Authorized Safaricom IP: #{request.remote_ip}"
      render json: { error: 'Not Authorized Safaricom IP' }, status: :not_found
    end
  end

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



  def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end



  # GET /hotspot_vouchers or /hotspot_vouchers.json
  # def index

  #   @hotspot_vouchers = HotspotVoucher.all.order(created_at: :desc)
  #   render json: @hotspot_vouchers
  
  # end


def index
   host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    # @hotspot_vouchers = HotspotVoucher.where(account_id: @account.id).order(created_at: :desc)
  @hotspot_vouchers =  HotspotVoucher
                        .where(account_id: @account.id)
                        .includes(:hotspot_mpesa_revenue, :hotspot_package)
                        .order(created_at: :desc)

                        package_names = @hotspot_vouchers.map(&:package).compact.uniq

packages_by_name = HotspotPackage.where(name: package_names, account_id: @account.id)
                                  .index_by(&:name)

router_names = packages_by_name.values.map(&:nas_router).compact.uniq

# 2. Cache each router's active-user list, keyed by router name via find_by
active_by_router = Rails.cache.fetch("active_users_#{@account.id}", expires_in: 10.seconds) do
  router_names.each_with_object({}) do |router_name, hash|
    nas = NasRouter.find_by(name: router_name, account_id: @account.id)
    next unless nas

    begin
      resp = RestClient::Request.execute(
        method: :get,
        url: "http://#{nas.ip_address}/rest/ip/hotspot/active",
        user: nas.username, password: nas.password,
        timeout: 3, open_timeout: 2
      )
      hash[router_name] = JSON.parse(resp.body).map { |u| u["user"] }
    rescue
      hash[router_name] = []
    end
  end
end

render json: @hotspot_vouchers, each_serializer: HotspotVoucherSerializer,
       packages_by_name: packages_by_name,
       active_by_router: active_by_router  
end








   def logout_user
  host = request.headers['X-Subdomain']
  @account = Account.find_by!(subdomain: host)

  voucher = HotspotVoucher.find_by(voucher: params[:voucher])
  return render json: 'Voucher not found', status: :not_found unless voucher

  package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
  return render json: 'Package not found', status: :unprocessable_entity unless package

  nas = NasRouter.find_by(name: package.nas_router, account_id: voucher.account_id)
  return render json: 'Router not found', status: :unprocessable_entity unless nas

  begin
    active_users = RestClient::Request.execute(
      method: :get,
      url: "http://#{nas.ip_address}/rest/ip/hotspot/active",
      user: nas.username,
      password: nas.password
    )

    users = JSON.parse(active_users.body)
    active = users.find { |u| u["user"] == voucher.voucher }

    unless active
      return render json: 'User is not currently online', status: :unprocessable_entity
    end

    response = RestClient::Request.execute(
      method: :post,
      url: "http://#{nas.ip_address}/rest/ip/hotspot/active/remove",
      user: nas.username,
      password: nas.password,
      payload: { ".id": active[".id"] }.to_json,
      headers: { content_type: :json }
    )

    if response.code == 200
      HotspotVoucherChannel.broadcast_to(@account, {
        type: "voucher_online",
        is_online: false,
        voucher: voucher,
        id: voucher.id
      })

      render json: 'Successfully logged out user', status: :ok
    else
      render json: 'Failed to log out user', status: :unprocessable_entity
    end

  rescue RestClient::Unauthorized
    Rails.logger.info "REST auth failed for router #{nas.ip_address}"
    render json: 'Router authentication failed', status: :unprocessable_entity

  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "MikroTik REST error on #{nas.ip_address}: #{e.response}"
    render json: 'Router error', status: :unprocessable_entity

  rescue StandardError => e
    Rails.logger.info "REST error logging in device #{nas.ip_address}: #{e.message}"
    render json: 'Failed to log out user', status: :unprocessable_entity
  end
end




def transaction_status_result
  raw_body = request.body.read
  Rails.logger.info "MPESA STATUS CALLBACK: #{raw_body}"

  data = JSON.parse(raw_body) rescue {}

  result = data["Result"] || {}

  result_code = result["ResultCode"]
  transaction_id = result["TransactionID"]
  originator_conversation_id = result["OriginatorConversationID"]

  # Extract ResultParameters array safely
  params_array = result.dig("ResultParameters", "ResultParameter") || []

  # Convert array to hash
  params_hash = params_array.each_with_object({}) do |item, hash|
    hash[item["Key"]] = item["Value"]
  end

  receipt_no = params_hash["ReceiptNo"]
  amount = params_hash["Amount"]
  # phone_and_name = params_hash["DebitPartyName"]
  transaction_status = params_hash["TransactionStatus"]
  finalised_time = params_hash["FinalisedTime"]

  customer_phone_number = params_hash["DebitPartyName"].split(' - ')[0]
  customer_name = params_hash["DebitPartyName"].split(' - ')[1]
  

#   active_status = HotspotVoucher.find_by(phone: customer_phone_number,
#    status: 'active')
#   #  receipt_no = HotspotVoucher.find_by(phone: customer_phone_number).hotspot_mpesa_revenue.reference
# voucher_code = HotspotVoucher.find_by(phone: customer_phone_number,
#    status: 'active').voucher

   active_session = TemporarySession.find_by(
phone_number: customer_phone_number,
status: 'pending'
   )
hotspot_package = HotspotPackage.find_by(name: active_session.hotspot_package,
account_id: active_session.account_id
)
  # active_status = HotspotVoucher.find_or_create_by(phone: customer_phone_number,
  #  status: 'active')
  #  
  
    #   hotspot_mpesa_revenue = HotspotMpesaRevenue.find_by(
    #           reference: receipt_no,
    #  )

unless HotspotMpesaRevenue.exists?(reference: receipt_no)
  found_revenue = HotspotMpesaRevenue.find_or_create_by(
    reference: receipt_no,
    amount: amount,
    voucher: active_session.voucher_code,
    payment_method: "Mpesa",
    time_paid: finalised_time,
    name: customer_name,
    account_id: active_session.account_id,
    hotspot_voucher_id: active_session.hotspot_voucher_id
  )



   broadcast_hotspot_payment(
    account_id: active_session.account_id,
    kind: 'voucher',
    amount: amount,
    package: active_session.hotspot_package,
    name: customer_name,
    phone: customer_phone_number,
    payment_method: 'Mpesa',
    reference: receipt_no
  )
end



if_expired = found_revenue.hotspot_voucher.expiration < Time.current

if if_expired
  Rails.logger.info "Voucher expired"
  return render json: { error: 'Voucher expired' }, status: :unprocessable_entity
  
end

    


  voucher = HotspotVoucher.find_or_create_by(
      voucher: active_session.voucher_code,

)

voucher.update(
  package: active_session.hotspot_package,
  phone: active_session.phone_number,
  
  ip: active_session.ip,
  hotspot_package_id: hotspot_package.id,
account_id: active_session.account_id)
voucher.save!


# voucher_expiration = HotspotSetting.find_by(account_id: active_session.account_id).voucher_expiration


voucher_expiration = HotspotSetting.find_by(account_id: active_session.account_id)&.voucher_expiration
 use_radius = router_uses_radius?




 if use_radius
   
if voucher_expiration == 'Real-time expiration'
#  calculate_expiration_login_with_voucher(hotspot_package, voucher, session.account_id)

  calculate_expiration(active_session.hotspot_package, voucher,
 active_session.account_id)
create_voucher_radcheck(active_session.voucher_code,
      active_session.hotspot_package, 
active_session.account_id)

else

  calculate_expiration(active_session.hotspot_package, voucher,
 active_session.account_id)

 
  create_voucher_radcheck_accumulated_sessions(active_session.voucher_code,
      active_session.hotspot_package, 
active_session.account_id)
end
 else
   calculate_expiration(active_session.hotspot_package, voucher,
 active_session.account_id)

if voucher_expiration == 'Real-time expiration'
  
   sync_voucher_natively(voucher)
else
sync_voucher_natively_realtime_expiration(voucher)  
end
 end


#      create_voucher_radcheck(active_session.voucher_code,
#       active_session.hotspot_package, 
# active_session.account_id)




found_revenue.update(hotspot_voucher_id: voucher.id)

nas_routers = NasRouter.where(account_id: active_session.account_id, 
)
nas_routers.each do |nas|
  begin
    response = RestClient::Request.execute(
      method: :post,
      url: "http://#{nas.ip_address}/rest/ip/hotspot/active/login",
      user: nas.username,
      password: nas.password,
      payload: {
        ip: active_session.ip,
        user: active_session.voucher_code,
        password: active_session.voucher_code
      }.to_json,
      headers: {
        content_type: :json,
        accept: :json
      }
    )



       
    if response.code == 200
 
      
       


voucher.update(status: 'used', login_by: 'Trasnsaction Code')
       active_session.update(
        paid: true, connected: true,
        status: 'used'
       )
    end

  rescue RestClient::Unauthorized
    Rails.logger.info "REST auth failed for router #{nas.ip_address}"

  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "MikroTik REST error on #{nas.ip_address}: #{e.response}"

  rescue StandardError => e
    Rails.logger.info "REST error logging in device #{active_session.ip}: #{e.message} on router #{nas.ip_address}"
  end
end



end





def login_with_receipt_number

  shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.short_code
passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.passkey
consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_key
consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_secret
initiator = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.api_initiator_username
security_credentials = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.api_initiator_password
host = request.headers['X-Subdomain']
ip = params[:ip]
mac = params[:mac]



transaction_id = params[:receipt_number]
  transaction_status_query = TransactionStatusService.initiate_transaction_status_query(
   shortcode,passkey,consumer_key,
      consumer_secret,transaction_id,initiator,security_credentials,host
  )
# receipt_no = HotspotVoucher.find_by(phon: customer_phone_number).hotspot_mpesa_revenue.reference
  transaction_status_query_response = transaction_status_query[:response]
  Rails.logger.info("Transaction Status Query Response: #{transaction_status_query_response}")

# Find the record once
mpesa_revenue = HotspotMpesaRevenue.find_by(reference: transaction_id)

unless mpesa_revenue
  return render json: { error: 'Transaction does not exist, please wait we are checking your payment....... ' }, status: :not_found
end


# Safely check expiration through the association
if mpesa_revenue.hotspot_voucher&.expiration.present? && 
   mpesa_revenue.hotspot_voucher.expiration < Time.current
  return render json: { error: 'Session expired for voucher or username' }, status: :forbidden
end


  # if transaction_status_query[:success]
    
# present_voucher_or_username = HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.expiration.present?


nas_routers = NasRouter.where(account_id: mpesa_revenue.account_id)

# if present_voucher_or_username
  voucher_code = HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.voucher

voucher_object_going_to_sync_natively = HotspotVoucher.find_by(voucher_code: voucher_code)
    
  use_radius = router_uses_radius?

if use_radius
  if mpesa_revenue.hotspot_voucher.expiration.nil? 
  create_voucher_radcheck(mpesa_revenue.hotspot_voucher.voucher, 
  mpesa_revenue.hotspot_voucher.hotspot_package.name, 
  mpesa_revenue.account_id)


    calculate_expiration_login_with_voucher(
  mpesa_revenue.hotspot_voucher.hotspot_package, 
mpesa_revenue.hotspot_voucher, mpesa_revenue.account_id)
  end
else
sync_voucher_natively(voucher_object_going_to_sync_natively)
if mpesa_revenue.hotspot_voucher.expiration.nil? 
 
    calculate_expiration_login_with_voucher(
  mpesa_revenue.hotspot_voucher.hotspot_package, 
mpesa_revenue.hotspot_voucher, mpesa_revenue.account_id)
  end


end




    

  nas_routers.each do |nas|
  begin
    response = RestClient::Request.execute(
      method: :post,
      url: "http://#{nas.ip_address}/rest/ip/hotspot/active/login",
      user: nas.username,
      password: nas.password,
      payload: {
        ip: ip,
        user: voucher_code,
        password: voucher_code
      }.to_json,
      headers: {
        content_type: :json,
        accept: :json
      }
    )

      


    if response.code == 200



   HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.update!(status:"used",
   login_by:'Transaction Code', 
      last_logged_in: Time.now,
      used_voucher: true)

       package = HotspotPackage.find_by(name: HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.package)
       expiration_time = HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.expiration
       TemporarySession.find_by(ip: ip, mac: mac).update(paid: true, connected: true)
       render json: { message: 'Connected successfully', 
       device_ip: ip, username: voucher_code, 
       expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"), 
       package: package }, status: :ok
    end

  rescue RestClient::Unauthorized
    Rails.logger.info "REST auth failed for router #{nas.ip_address}"

  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "MikroTik REST error on #{nas.ip_address}: #{e.response}"

  rescue StandardError => e
    # Rails.logger.info "REST error logging in device #{active_status.ip}: #{e.message}"
  end



end

    
  # else
  #   render json: { error: 'Failed to fetch transaction status' }, status: :unprocessable_entity
  # end

end






  def hotspot_traffic
  account_id = ActsAsTenant.current_tenant&.id
  use_radius = router_uses_radius?

  # ← cache key now scoped per-tenant AND per-mode, so radius/native
  # accounts (and different tenants) never share cached data
  cache_key = "hotspot_traffic_#{account_id}_#{use_radius}_#{Time.current.beginning_of_minute.to_i}"

  hotspot_data = Rails.cache.fetch(cache_key, expires_in: 10.seconds) do
    if use_radius
      fetch_hotspot_traffic_via_radius
    else
      fetch_hotspot_traffic_natively(account_id)
    end
  end

  hotspot_data[:cache_hit] = true unless hotspot_data[:cache_hit]

  render json: hotspot_data
end


# ── Existing RadAcct-based logic, unchanged, just extracted ──
def fetch_hotspot_traffic_via_radius
  total_bytes = 0
  total_bytes_upload_download = 0
  total_bytes_upload = 0
  total_bytes_download = 0

  active_sessions_upload_download = RadAcct.where(
    acctstoptime: nil,
    framedprotocol: ''
  ).where('acctupdatetime > ?', 3.minutes.ago)

  active_sessions = RadAcct.where(
    acctstoptime: nil,
    framedprotocol: ""
  ).where('acctupdatetime > ?', 3.minutes.ago)

  active_sessions_upload_download.each do |session|
    download_bytes = session.acctinputoctets || 0
    upload_bytes = session.acctoutputoctets || 0
    total_bytes_download += download_bytes
    total_bytes_upload += upload_bytes
    session_total = download_bytes + upload_bytes
    total_bytes_upload_download += session_total
  end

  active_user_data = active_sessions.map do |session|
    download_bytes = session.acctinputoctets || 0
    upload_bytes = session.acctoutputoctets || 0
    session_total = download_bytes + upload_bytes
    total_bytes += session_total

    {
      username: session.username,
      ip_address: session.framedipaddress.to_s,
      mac_address: session.callingstationid,
      up_time: format_uptime(session.acctsessiontime),
      download: format_bytes(download_bytes),
      upload: format_bytes(upload_bytes),
      start_time: session.acctstarttime&.strftime("%B %d, %Y at %I:%M %p") || "Unknown",
      nas_port: session.nasportid,
      last_update: session.acctupdatetime&.iso8601 || Time.current.iso8601
    }
  end

  {
    active_user_count: active_user_data.size,
    total_upload: format_bytes(total_bytes_upload),
    total_download: format_bytes(total_bytes_download),
    total_bandwidth: format_bytes(total_bytes_upload_download),
    users: active_user_data,
    timestamp: Time.current.iso8601,
    cache_hit: false
  }
end

# ── New native MikroTik REST logic, used when use_radius is false ──
def fetch_hotspot_traffic_natively(account_id)
  nas_routers = NasRouter.where(account_id: account_id)

  total_bytes_upload = 0
  total_bytes_download = 0
  active_user_data = []

  nas_routers.each do |nas|
    begin
      response = RestClient::Request.execute(
        method: :get,
        url: "http://#{nas.ip_address}/rest/ip/hotspot/active",
        user: nas.username,
        password: nas.password,
        timeout: 5,
        open_timeout: 3
      )

      users = JSON.parse(response.body)
      next unless users.is_a?(Array)

      users.each do |user|
        download_bytes = user["bytes-in"].to_i
        upload_bytes = user["bytes-out"].to_i
        total_bytes_download += download_bytes
        total_bytes_upload += upload_bytes

        active_user_data << {
          username: user["user"],
          ip_address: user["address"],
          mac_address: user["mac-address"],
          up_time: user["uptime"],
          download: format_bytes(download_bytes),
          upload: format_bytes(upload_bytes),
          start_time: nil,
          nas_port: nil,
          last_update: Time.current.iso8601
        }
      end

    rescue RestClient::Unauthorized
      Rails.logger.error "hotspot_traffic: REST auth failed for router #{nas.ip_address}"
      next
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "hotspot_traffic: MikroTik REST error on #{nas.ip_address}: #{e.response}"
      next
    rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
      Rails.logger.error "hotspot_traffic: Timed out reaching router #{nas.ip_address}"
      next
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
      Rails.logger.error "hotspot_traffic: Router #{nas.ip_address} unreachable: #{e.message}"
      next
    rescue StandardError => e
      Rails.logger.error "hotspot_traffic: Failed to fetch from #{nas.ip_address}: #{e.message}"
      next
    end
  end

  total_bandwidth = total_bytes_download + total_bytes_upload

  {
    active_user_count: active_user_data.size,
    total_upload: format_bytes(total_bytes_upload),
    total_download: format_bytes(total_bytes_download),
    total_bandwidth: format_bytes(total_bandwidth),
    users: active_user_data,
    timestamp: Time.current.iso8601,
    cache_hit: false
  }
end






def check_payment_status
  raw_body = request.body.read

  data = JSON.parse(raw_body) rescue {}
  bill_ref = data["BillRefNumber"]

  if bill_ref.start_with?("hotspot_")
    # Remove "hotspot_" prefix and extract session_id and voucher_code
    parts = bill_ref.sub("hotspot_", "").split("_")
    session_id = parts[0]
    voucher_code = parts[1]
        session = TemporarySession.find_by(session: session_id, 
        )



if session&.payment_type == 'device_binding'

  tv_plan = TvPlan.find_by(id: session.tv_plan_id, account_id: session.account_id)
      # nas_router_tv_package = NasRouter.find_by(name: tv_plan.nas_router, account_id: tv_plan.account_id)
      nas_router_tv_package = NasRouter.find_by(id: tv_plan.nas_router_id, account_id: tv_plan.account_id)

  binding = IpBinding.create!(
    name:        session&.device_name,
    mac:         session&.device_mac,
    package:     tv_plan&.name,
    ip:          session&.ip,
    tv_plan_id:  tv_plan&.id,
    phone:       session&.phone_number,
    source:      'tv_plan_purchase',
    status:      'active',
    device_type: session&.device_type,
    account_id:  session&.account_id,
    router_id:   nas_router_tv_package&.id,
    expiry:      tv_plan ? tv_plan_expiration(tv_plan) : nil
  )

  HotspotMpesaRevenue.create!(
    amount: data["TransAmount"], voucher: "DEVICE-#{binding.mac}",
    reference: data["TransID"], payment_method: "Mpesa",
    time_paid: data["TransTime"], account_id: session.account_id,
    name: data["FirstName"], phone_number: session.phone_number,
    status: "Completed",
    payment_type: "tv_plan",          # ← NEW: lets admin filter/badge these
    tv_plan_id: tv_plan&.id,          # ← NEW
    device_name: binding.name         # ← NEW
  )


broadcast_hotspot_payment(
    account_id: session.account_id,
    kind: 'tv_plan',
    amount: data["TransAmount"],
    package: tv_plan&.name,
    name: data["FirstName"],
    phone: session.phone_number,
    payment_method: 'Mpesa',
    reference: data["TransID"]
  )


  if nas_router_tv_package

    begin
       mikrotik_add_binding_direct(binding, nas_router_tv_package)              
    mikrotik_add_queue_for_tv_plan(binding, tv_plan, nas_router_tv_package) if tv_plan


    rescue => e
          Rails.logger.error "MikroTik binding failed for #{binding.mac}: #{e.message}"

          Rails.logger.error e.backtrace.join("\n")

    end
  end
  send_tv_plan_confirmation_sms(binding, tv_plan, session)   # ← NEW: was defined but never called

  session.update!(connected: true, status: 'used', paid: true)
  head :ok
  return
end


 hotspot_package = HotspotPackage.find_by(
      name:       session&.hotspot_package,
      account_id: session&.account_id,
  )

    nas_router = NasRouter.find_by(name: hotspot_package&.nas_router, account_id: hotspot_package&.account_id)



  
        # voucher = HotspotVoucher.find_by(voucher: voucher_code)
hotspot_package = HotspotPackage.find_by(name: session.hotspot_package,
account_id: session.account_id

)
        voucher = HotspotVoucher.create!(
  package: session.hotspot_package,
  phone: session.phone_number,
  voucher: session.voucher_code,
  mac: session.mac,
  ip: session.ip,
  checkout_request_id: session.checkout_request_id,
account_id: session.account_id,
  hotspot_package_id: hotspot_package.id,
  status: 'active'
)
 session.update(hotspot_voucher_id: voucher.id)




# company_name = CompanySetting.find_by(account_id: session.account_id).company_name

voucher_expiration = HotspotSetting.find_by(account_id: session.account_id)&.voucher_expiration
 
 use_radius = router_uses_radius_payment(session.account_id)
 if use_radius
   if voucher_expiration == 'Real-time expiration'
 calculate_expiration_login_with_voucher(hotspot_package, voucher, session.account_id)

create_voucher_radcheck(voucher_code, session.hotspot_package, 
session.account_id)

else
   calculate_expiration_login_with_voucher(hotspot_package, voucher, session.account_id)

  create_voucher_radcheck_accumulated_sessions(voucher_code, session.hotspot_package, 
session.account_id)
end
 else
     calculate_expiration_login_with_voucher(hotspot_package, voucher, session.account_id)

if voucher_expiration == 'Real-time expiration'
  
   sync_voucher_natively(voucher)
else
sync_voucher_natively_realtime_expiration(voucher)  
end
 end



SendSmsHotspotService.send_sms(voucher.voucher, data, session.checkout_request_id,
)


broadcast_hotspot_payment(
  account_id: session.account_id,
  kind: 'voucher',
  amount: data["TransAmount"],
  package: session.hotspot_package,
  name: data["FirstName"],
  phone: session.phone_number,
  payment_method: 'Mpesa',
  reference: data["TransID"]
)
  if nas_router
  begin
    response = RestClient::Request.execute(
      method: :post,
      url: "http://#{nas_router.ip_address}/rest/ip/hotspot/active/login",
      user: nas_router.username,
      password: nas_router.password,
      payload: {
        ip: session.ip,
        user: voucher_code,
        password: voucher_code
      }.to_json,
      headers: {
        content_type: :json,
        accept: :json
      },
      timeout: 5,
      open_timeout: 3
    )

    if response.code == 200
      session.update!(connected: true, status: "used", paid: true)

      voucher.update!(
        status: "used",
        last_logged_in: Time.current,
        used_voucher: true,
        login_by: "Voucher Code"
      )
    end

  rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
    Rails.logger.info "Router #{nas_router.ip_address} timed out during login"

  rescue RestClient::Unauthorized
    Rails.logger.info "REST auth failed for router #{nas_router.ip_address}"

  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "MikroTik REST error on #{nas_router.ip_address}: #{e.response}"

  rescue StandardError => e
    Rails.logger.info "REST error logging in device #{session.ip}: #{e.message}"
  end
else
  Rails.logger.warn "No router found for account #{session.account_id}"
end

elsif bill_ref.start_with?("smswallet_")
  # bill_ref = "smswallet_<account_id>_<txn_id>"
  parts = bill_ref.sub("smswallet_", "").split("_")
  account_id = parts[0]
  txn_id = parts[1]

  txn = TenantSmsWalletTransaction.find_by(id: txn_id, account_id: account_id)
  unless txn
    Rails.logger.warn "check_payment_status: no sms wallet txn for #{bill_ref}"
    head :ok and return
  end

  # Idempotency guard — M-Pesa retries confirmation callbacks that don't
  # get acked fast enough, which would otherwise double-credit the wallet.
  if txn.status == 'completed'
    Rails.logger.info "check_payment_status: sms wallet txn #{txn.id} already completed, ignoring duplicate callback"
    head :ok and return
  end

  paid_amount = data["TransAmount"].to_f
  wallet = TenantSmsWallet.find_by(account_id: account_id)

  if paid_amount >= txn.amount.to_f
    wallet.complete_purchase!(txn, paid_amount: paid_amount)
    Rails.logger.info "SMS wallet credited: account #{account_id}, +#{txn.quantity} credits"
  else
    txn.update!(status: 'underpaid')
    Rails.logger.warn "SMS wallet purchase underpaid: expected #{txn.amount}, got #{paid_amount}"
  end


elsif data["BillRefNumber"].starts_with?("INV")
  bill_ref    = data["BillRefNumber"]
  paid_amount = data["TransAmount"].to_i

  invoice = Invoice.find_by(invoice_number: bill_ref)

  unless invoice
    Rails.logger.warn "check_payment_status: no invoice found for #{bill_ref}"
    head :ok and return
  end

  # Record the payment regardless of whether it fully settles the invoice —
  # this is now the system admin's source of truth for "what did this ISP
  # actually pay", independent of the invoice's current status.
  ActsAsTenant.with_tenant(Account.find_by(id: invoice.account_id)) do
    InvoicePayment.find_or_create_by!(reference: data["TransID"]) do |p|
      p.invoice_id    = invoice.id
      p.account_id    = invoice.account_id
      p.phone_number  = data["MSISDN"] || data["DebitPartyMSISDN"]
      p.payer_name    = data["FirstName"]
      p.amount        = paid_amount
      p.paid_at       = Time.current
      p.status        = paid_amount >= invoice.total.to_i ? 'completed' : 'partial'
    end
  end

  if invoice.status == 'unpaid' && invoice.total.to_i == paid_amount
    invoice.update!(
      status: 'paid',
      amount_paid: paid_amount,
      total: data["TransAmount"],
      plan_name: "Hotspot And PPPOE Plan"
    )

    tenant = Account.find_by(id: invoice.account_id)
    tenant.hotspot_and_dial_plan.update(
      name: 'Hotspot And PPPOE Plan',
      # expiry: Time.current + 30.days,
      expiry: (tenant.hotspot_and_dial_plan.expiry || Time.current) + 30.days,
      expiry_days: 30
    )
  end



  
  else

 bill_ref = data["BillRefNumber"]

  # subscriber_account_number = Subscriber.find_by(ref_no:  bill_ref).ref_no
  
  found_subscriber = Subscriber.find_by(ref_no:  bill_ref)
  nas_routers = NasRouter.where(account_id: found_subscriber.account_id)
        subscription = Subscription.find_by(subscriber_id: found_subscriber.id, 
        account_id: found_subscriber.account_id)
paid_amount = data["TransAmount"].to_i
         

        
  subscriber_phone_number = Subscriber.find_by(id: subscription.subscriber_id).phone_number

pppoe_package = Package.find_by(name: subscription.package_name)

total_wallet_balance = PpPoeMpesaRevenue
  .where(account_number: bill_ref)
  .sum(:amount)


   pppoe_revenue = PpPoeMpesaRevenue.create(
      amount: data["TransAmount"],
      payment_method: "Mpesa",
      time_paid: data["TransTime"],
      account_number:  bill_ref,
      reference: data["TransID"],
      customer_name: data['FirstName'],
      payment_type: "Deposit",
      account_id: found_subscriber.account_id,
      subscriber_id: subscription.subscriber_id

    )

    if pppoe_package.price === data["TransAmount"].to_i
     SubscriberTransaction.create!(
            transaction_type: 'Payment',
            debit: pppoe_revenue.amount,
            date:  pppoe_revenue.time_paid,
            title:  pppoe_package.name,
            description: "Payment for internet subscription",
            account_id:  pppoe_revenue.account_id,
            subscriber_id: pppoe_revenue.subscriber_id
          )




          SubscriberTransaction.create!(
            transaction_type: 'Deposit',
            credit: pppoe_revenue.amount,
            date:  pppoe_revenue.time_paid,
            title:   pppoe_revenue.reference,
            description: "Payment made via M-Pesa",
            account_id:  pppoe_revenue.account_id,
            subscriber_id: pppoe_revenue.subscriber_id
          )

    else
      SubscriberTransaction.create!(
            transaction_type: 'Deposit',
            credit: pppoe_revenue.amount,
            date:  pppoe_revenue.time_paid,
            title:  pppoe_revenue.reference,
            description: "Payment made via M-Pesa",
            account_id:  pppoe_revenue.account_id,
            subscriber_id: pppoe_revenue.subscriber_id)

    end
       @subscriber_wallet_balance = SubscriberWalletBalance.first_or_initialize(
        subscriber_id: pppoe_revenue.subscriber_id,
        amount: total_wallet_balance,
       account_id: pppoe_revenue.account_id
      )
      @subscriber_wallet_balance.update(
         subscriber_id: pppoe_revenue.subscriber_id,
        amount: total_wallet_balance,
       account_id: pppoe_revenue.account_id
      )
        # package_amount_paid = data["TransAmount"]
  # expiration_time = Time.parse(subscription.expiration_date.to_s)


        # expiration_time > Time.current
        # paid_right_amount = Package.find_by(
        #   account_id: subscription.account_id,
 #   amount: package_amount_paid
        # )

        if pppoe_package.price === data["TransAmount"].to_i

 invoice = SubscriberInvoice
  .where(
    subscriber_id: found_subscriber.id,
    account_id: found_subscriber.account_id,
    status: "unpaid"
  )
  .order(:invoice_date)
  .firs
       invoice.update!(status: 'paid', description: "Invoice paid for
           wifi package => #{subscription.package_name}",
           
           amount: paid_amount,
           )
        end

          
# company_name, account_no, tenant
company_name = CompanySetting.find_by(account_id: subscription.account_id)
# send_invoice_paid_notification = SubscriberSetting.find_by(account_id: found_subscriber.account_id)&.invoice_created_or_paid

        #   if send_invoice_paid_notification
        # SendInvoicePaidJob.perform_now(
        #   company_name.company_name,
        #   bill_ref,
        #   invoice.account,
        #   subscriber_phone_number
        # )
        #   end


        if pppoe_package.price === data["TransAmount"].to_i
           SendInvoicePaidJob.perform_now(
          company_name.company_name,
          bill_ref,
          found_subscriber.account,
          subscriber_phone_number
        )

         subscription.update(invoice_expired_created_at:  nil)


          if subscription.status === 'blocked'
             subscription.update!(status: 'active', expiry: Time.current + 30.days)

          end


            if subscription.status === 'blocked'

nas_routers.each do |nas|
      Rails.logger.info "PPPOE payment received: #{bill_ref}"
    #  ping_result = system("ping -c 1 -W 2 #{nas.ip_address}")

      Net::SSH.start(nas.ip_address, nas.username, password: nas.password,
         
      verify_host_key: :never, non_interactive: true) do |ssh|
          # Correct command to remove active PPPoE session based on pppoe_username
          command = "/ip firewall address-list remove [find list=aitechs_blocked_list address=#{subscription.ip_address}]"
          
          # Execute the command
          ssh.exec!(command)
          if subscription.status === 'blocked'
             subscription.update!(status: 'active', expiry: Time.current + 30.days)

          end
          puts "UnBlocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik."
        end
      end
    end
      # rescue StandardError => e
      #   Rails.logger.error "Error removing PPPoE connection for username #{subscription.ppoe_username}: #{e.message}"
      # end
end
        

   

   
  end

  head :ok
end






def payment_and_conected_status
  # session = TemporarySession.find_by(ip: params[:ip])

  # if session.paid && session.connected
  #  render json: { paid: session.paid, connected: session.connected}
  # end
  ip  = params[:ip]
  mac = params[:mac]

  cache_key = "payment_status:#{ip}:#{mac}"

  status = Rails.cache.fetch(cache_key, expires_in: 10.seconds) do
    session = TemporarySession.find_by(ip: ip)

    {
      paid: session&.paid || false,
      connected: session&.connected || false
    }
  end

  render json: status
end




# def stk_push_status
#     shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.short_code || ENV['B2C_SHORTCODE']
#   passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.passkey || ENV['PASSKEY']
#   consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_key || ENV['CONSUMER_KEY']
#   consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_secret || ENV['CONSUMER_SECRET']
#  checkout_request_id = params[:checkout_request_id]
# Rails.logger.info "checkout_request_id: #{checkout_request_id}"
#   stk_push_query = StkStatusService.initiate_stk_query(
#     shortcode,  passkey,
#     consumer_key, consumer_secret,checkout_request_id
#   )


#   if stk_push_query[:success]
#     stk_push_query_response = stk_push_query[:response]
#     render json: { success: true, response: stk_push_query_response }
#   else
#     render json: { error: 'Failed to fetch stk push status'}
#   end


# end








def stk_push_status
  shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.short_code.presence || ENV['B2C_SHORTCODE']
  passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.passkey.presence || ENV['PASSKEY']
  consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_key.presence || ENV['CONSUMER_KEY']
  consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_secret.presence || ENV['CONSUMER_SECRET']

  checkout_request_id = params[:checkout_request_id]

  Rails.logger.info "checkout_request_id: #{checkout_request_id}"

  stk_push_query = StkStatusService.initiate_stk_query(
    shortcode,
    passkey,
    consumer_key,
    consumer_secret,
    checkout_request_id
  )

  unless stk_push_query[:success]
    return render json: { error: "Failed to fetch stk push status" }
  end

  stk_push_query_response = stk_push_query[:response]

  revenue = HotspotMpesaRevenue.find_by(
    checkout_request_id: checkout_request_id
  )

  if revenue.present?
    case stk_push_query_response["ResultCode"].to_s
    when "0"
      revenue.update(status: "Completed")

    when "1037"
      revenue.update(status: "Pending")

      when "4999"
      revenue.update(status: "Pending")

    else
      revenue.update(status: "Cancelled")
    end
  end

  render json: {
    success: true,
    response: stk_push_query_response
  }
end




def receipt_number_status
 active_session = TemporarySession.find_by(ip: params[:ip])
 if active_session
  render json: { paid: active_session.paid, connected: active_session.connected }
 else
  render json: { paid: false, connected: false }
 end
end




# def make_payment
# host = request.headers['X-Subdomain']

# plan = ActsAsTenant.current_tenant&.hotspot_and_dial_plan

#   expired_pppoe = plan&.expiry.present? && plan.expiry <= Time.current



#   if expired_pppoe
#     return render json: { error: 'License has expired'}, status: 422  
#   end

#   phone_number = params[:phone_number]

# if phone_number.blank?
#     return render json: { error: 'Phone number is required to make a payment' }, status: :unprocessable_entity
#   end

#   amount = params[:amount]
#   shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.short_code || ENV['B2C_SHORTCODE']
#   passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.passkey || ENV['PASSKEY']
#   consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_key || ENV['CONSUMER_KEY']
#   consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_secret || ENV['CONSUMER_SECRET']

# #   session_id = rand(100000..999999).to_s
# # TemporarySession.create!(
# #   session: session_id,
# #   ip: params[:ip],    
# # )

# session_id = rand(100000..999999).to_s



#  tuma_setting = TumaSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
#   use_tuma = tuma_setting&.enabled && tuma_setting.use_for_hotspot




#   if use_tuma
#     full_domain = request.headers['X-Domain']
#     base_domain = full_domain.to_s.split('.').last(3).join('.') if full_domain.present?
#     platform_domain = base_domain == "owitech.co.ke" ? "owitech.co.ke" : "aitechs.co.ke"
#     callback_url = "https://#{host}.#{platform_domain}/api/tuma/hotspot_callback/#{session_id}"

#     result = TumaService.initiate_stk_push(
#       tuma_setting, amount: amount, phone: phone_number,
#       callback_url: callback_url, description: "Hotspot package #{params[:package]}"
#     )

#     if result[:success]
#       checkout_request_id = result[:response]['checkout_request_id']
#       session.update!(checkout_request_id: checkout_request_id)
#       HotspotMpesaRevenue.create!(voucher: voucher_code, amount: amount, payment_method: 'Tuma',
#         phone_number: phone_number, status: 'Pending', checkout_request_id: checkout_request_id)
#       return render json: { message: 'Please check your phone to complete the payment', checkout_request_id: checkout_request_id }
#     else
#       return render json: { error: result[:error] || 'Failed to initiate Tuma payment' }, status: :unprocessable_entity
#     end
#   end


#       hotspot_payment = MpesaService.initiate_stk_push(phone_number, 
#       amount,
#        shortcode,  passkey,
#         consumer_key, consumer_secret, host,voucher_code,session_id
#       )
  
#  stk_response = hotspot_payment[:response]
#  checkout_request_id = stk_response['CheckoutRequestID']
# #  merchant_request_id = stk_response['MerchantRequestID']





# session = TemporarySession.find_or_initialize_by(ip: params[:ip],
# session: session_id,
# paid: false, 
# connected: false,
# hotspot_package: params[:package],
# voucher_code: voucher_code,
# phone_number: phone_number,
# mac: params[:mac],
# status: 'pending',
# checkout_request_id: checkout_request_id,
#  payment_gateway: use_tuma ? 'tuma' : 'mpesa'

# )





# session.save!



#       if hotspot_payment[:success]
# # voucher_record = HotspotVoucher.create!(
# #   package: params[:package],
# #   phone: phone_number,
# #   voucher: voucher_code,
# #   mac: params[:mac],
# #   ip: params[:ip],
# #   checkout_request_id: checkout_request_id,
# #   merchant_request_id: merchant_request_id,

# #   payment_status: 'pending'

# # )

# # create_voucher_radcheck(voucher_code, params[:package], 
# # voucher_record.account_id)

# # calculate_expiration(params[:package], voucher_record)


# HotspotMpesaRevenue.create!(
#   voucher: voucher_code,
#   amount: amount,
#   payment_method: "Mpesa",
#   phone_number: phone_number,
#   status: "Pending",
#   checkout_request_id: checkout_request_id
# )



#         render json: {
#           message: 'Please check your phone to complete the payment',
#           checkout_request_id: checkout_request_id
#         }
#       else
#         render json: { error: 'Failed to initiate payment' }, status: :unprocessable_entity
#       end
# end



def payment_reference_status
  reference = params[:reference] || params[:checkout_request_id]
  revenue = HotspotMpesaRevenue.find_by(checkout_request_id: reference)
  return render json: { error: 'Not found' }, status: :not_found unless revenue

  session = TemporarySession.find_by(checkout_request_id: reference)

  render json: {
    success: true,
    status: revenue.status,          # 'Pending' | 'Completed' | 'Cancelled'
    connected: session&.connected || false,
    package: session&.hotspot_package
  }
end





# def make_payment
#   host = request.headers['X-Subdomain']

#   plan = ActsAsTenant.current_tenant&.hotspot_and_dial_plan
#   expired_pppoe = plan&.expiry.present? && plan.expiry <= Time.current

#   if expired_pppoe
#     return render json: { error: 'License has expired'}, status: 422  
#   end

#   phone_number = params[:phone_number]
#   if phone_number.blank?
#     return render json: { error: 'Phone number is required to make a payment' }, status: :unprocessable_entity
#   end

#   amount = params[:amount]
#   shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.short_code || ENV['B2C_SHORTCODE']
#   passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.passkey || ENV['PASSKEY']
#   consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_key || ENV['CONSUMER_KEY']
#   consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_secret || ENV['CONSUMER_SECRET']

#   voucher_code = generate_voucher_code
#   session_id = rand(100000..999999).to_s

#   tuma_setting = TumaSetting.find_by(account_id: ActsAsTenant.current_tenant.id)

#   active_gateway = PaymentGatewaySetting.active_gateway_for(ActsAsTenant.current_tenant.id, 'hotspot')

#   tuma_setting = TumaSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
#   use_tuma = active_gateway == 'tuma' && tuma_setting&.enabled

#   paystack_setting = PaystackSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
#   use_paystack = active_gateway == 'paystack' && paystack_setting&.enabled

#   gateway_label = use_tuma ? 'tuma' : (use_paystack ? 'paystack' : 'mpesa')

#   temp_session = TemporarySession.find_or_initialize_by(
#     ip: params[:ip], session: session_id, paid: false, connected: false,
#     hotspot_package: params[:package], voucher_code: voucher_code,
#     phone_number: phone_number, mac: params[:mac], status: 'pending',
#     payment_gateway: gateway_label
#   )


#   if use_paystack
#     reference = "hotspot_#{session_id}_#{voucher_code}"

#     result = PaystackService.initiate_mobile_money_charge(
#       paystack_setting, amount: amount, phone: phone_number, email: nil,
#       reference: reference, metadata: { package: params[:package], session_id: session_id }
#     )

#     if result[:success]
#       temp_session.update!(checkout_request_id: reference)
#       HotspotMpesaRevenue.create!(
#         voucher: voucher_code, amount: amount, payment_method: 'Paystack',
#         phone_number: phone_number, status: 'Pending', checkout_request_id: reference
#       )
#       return render json: {
#         message: result[:display_text].presence || 'Please check your phone to complete the payment',
#         checkout_request_id: reference
#       }
#     else
#       return render json: { error: result[:error] || 'Failed to initiate Paystack payment' }, status: :unprocessable_entity
#     end
#   end
  

#   if use_tuma
#     full_domain = request.headers['X-Domain']
#     base_domain = full_domain.to_s.split('.').last(3).join('.') if full_domain.present?
#     platform_domain = base_domain == "owitech.co.ke" ? "owitech.co.ke" : "aitechs.co.ke"
#     callback_url = "https://#{host}.#{platform_domain}/api/tuma/hotspot_callback/#{session_id}"

#     result = TumaService.initiate_stk_push(
#       tuma_setting, 
#       amount: amount, 
#       phone: phone_number,
#       callback_url: callback_url, 
#       description: "Hotspot package #{params[:package]}"
#     )

#     if result[:success]
#       checkout_request_id = result[:response]['checkout_request_id']
#       # ✅ NOW THIS WORKS
#       temp_session.update!(checkout_request_id: checkout_request_id)
      
#       HotspotMpesaRevenue.create!(
#         voucher: voucher_code, 
#         amount: amount, 
#         payment_method: 'Tuma',
#         phone_number: phone_number, 
#         status: 'Pending', 
#         checkout_request_id: checkout_request_id
#       )
      
#       return render json: { 
#         message: 'Please check your phone to complete the payment', 
#         checkout_request_id: checkout_request_id 
#       }
#     else
#       return render json: { error: result[:error] || 'Failed to initiate Tuma payment' }, status: :unprocessable_entity
#     end
#   end

#   # Fallback to M-Pesa
#   hotspot_payment = MpesaService.initiate_stk_push(
#     phone_number, 
#     amount,
#     shortcode,  
#     passkey,
#     consumer_key, 
#     consumer_secret, 
#     host,
#     voucher_code,
#     session_id
#   )
  
#   stk_response = hotspot_payment[:response]
#   checkout_request_id = stk_response['CheckoutRequestID']

#   # ✅ USE temp_session, not session
#   temp_session.checkout_request_id = checkout_request_id
#   temp_session.save!

#   if hotspot_payment[:success]
#     HotspotMpesaRevenue.create!(
#       voucher: voucher_code,
#       amount: amount,
#       payment_method: "Mpesa",
#       phone_number: phone_number,
#       status: "Pending",
#       checkout_request_id: checkout_request_id
#     )

#     render json: {
#       message: 'Please check your phone to complete the payment',
#       checkout_request_id: checkout_request_id
#     }
#   else
#     render json: { error: 'Failed to initiate payment' }, status: :unprocessable_entity
#   end
# end



def make_payment
  host = request.headers['X-Subdomain']

  plan = ActsAsTenant.current_tenant&.hotspot_and_dial_plan
  expired_pppoe = plan&.expiry.present? && plan.expiry <= Time.current

  if expired_pppoe
    return render json: { error: 'License has expired'}, status: 422  
  end

  phone_number = params[:phone_number]
  if phone_number.blank?
    return render json: { error: 'Phone number is required to make a payment' }, status: :unprocessable_entity
  end

  amount = params[:amount]
  shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.short_code.presence || ENV['B2C_SHORTCODE']
passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.passkey.presence || ENV['PASSKEY']
consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_key.presence || ENV['CONSUMER_KEY']
consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting&.consumer_secret.presence || ENV['CONSUMER_SECRET']


  voucher_code = generate_voucher_code
  session_id = rand(100000..999999).to_s

  active_gateway = PaymentGatewaySetting.active_gateway_for(ActsAsTenant.current_tenant.id, 'hotspot')

  tuma_setting = TumaSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
  use_tuma = active_gateway == 'tuma' && tuma_setting&.enabled

  paystack_setting = PaystackSetting.find_by(account_id: ActsAsTenant.current_tenant.id)
  use_paystack = active_gateway == 'paystack' && paystack_setting&.enabled

  gateway_label = use_tuma ? 'tuma' : (use_paystack ? 'paystack' : 'mpesa')

  temp_session = TemporarySession.find_or_initialize_by(
    ip: params[:ip], session: session_id, paid: false, connected: false,
    hotspot_package: params[:package], voucher_code: voucher_code,
    phone_number: phone_number, mac: params[:mac], status: 'pending',
    payment_gateway: gateway_label
  )

  if use_paystack
    reference = "hotspot_#{session_id}_#{voucher_code}"

    result = PaystackService.initiate_mobile_money_charge(
      paystack_setting, amount: amount, phone: phone_number, email: nil,
      reference: reference, metadata: { package: params[:package], session_id: session_id }
    )

    if result[:success]
      temp_session.update!(checkout_request_id: reference)
      HotspotMpesaRevenue.create!(
        voucher: voucher_code, amount: amount, payment_method: 'Paystack',
        phone_number: phone_number, status: 'Pending', checkout_request_id: reference
      )
      return render json: {
        message: result[:display_text].presence || 'Please check your phone to complete the payment',
        checkout_request_id: reference,
        gateway: gateway_label  
      }
    else
      return render json: { error: result[:error] || 'Failed to initiate Paystack payment' }, status: :unprocessable_entity
    end
  end

  if use_tuma
    full_domain = request.headers['X-Domain']
    base_domain = full_domain.to_s.split('.').last(3).join('.') if full_domain.present?
    platform_domain = base_domain == "owitech.co.ke" ? "owitech.co.ke" : "aitechs.co.ke"
    callback_url = "https://#{host}.#{platform_domain}/api/tuma/hotspot_callback/#{session_id}"

    result = TumaService.initiate_stk_push(
      tuma_setting,
      amount: amount,
      phone: phone_number,
      callback_url: callback_url,
      description: "Hotspot package #{params[:package]}"
    )

    if result[:success]
      checkout_request_id = result[:response]['checkout_request_id']
      temp_session.update!(checkout_request_id: checkout_request_id)

      HotspotMpesaRevenue.create!(
        voucher: voucher_code,
        amount: amount,
        payment_method: 'Tuma',
        phone_number: phone_number,
        status: 'Pending',
        checkout_request_id: checkout_request_id
      )

      return render json: {
        message: 'Please check your phone to complete the payment',
        checkout_request_id: checkout_request_id,
        gateway: gateway_label  
      }
    else
      return render json: { error: result[:error] || 'Failed to initiate Tuma payment' }, status: :unprocessable_entity
    end
  end

  # Fallback to M-Pesa
  hotspot_payment = MpesaService.initiate_stk_push(
    phone_number,
    amount,
    shortcode,
    passkey,
    consumer_key,
    consumer_secret,
    host,
    voucher_code,
    session_id
  )

  # MpesaService can fail before ever reaching Safaricom (e.g. "Error fetching
  # access token") and return {success: false, error: "..."} with no :response
  # key at all. Guard on success before touching [:response] so a credential
  # or network failure returns a clean 422 instead of a 500.
  unless hotspot_payment[:success]
    return render json: { error: hotspot_payment[:error] || 'Failed to initiate payment' }, status: :unprocessable_entity
  end

  stk_response = hotspot_payment[:response]
  checkout_request_id = stk_response && stk_response['CheckoutRequestID']

  unless checkout_request_id
    return render json: { error: 'Failed to initiate payment: no checkout request ID returned' }, status: :unprocessable_entity
  end

  temp_session.checkout_request_id = checkout_request_id
  temp_session.save!

  HotspotMpesaRevenue.create!(
    voucher: voucher_code,
    amount: amount,
    payment_method: "Mpesa",
    phone_number: phone_number,
    status: "Pending",
    checkout_request_id: checkout_request_id
  )

  render json: {
    message: 'Please check your phone to complete the payment',
    checkout_request_id: checkout_request_id,
    gateway: gateway_label  
  }
end



  
def expired_vouchers
  expired_voucher = HotspotVoucher.where(status: 'expired').count
  render json: {expired_voucher: expired_voucher}, status: :ok
end



def active_vouchers
  active_voucher = HotspotVoucher.where(status: 'active').count
  render json: {active_voucher: active_voucher}, status: :ok

end





def send_voucher_to_phone_number
    company_name = ActsAsTenant.current_tenant&.company_setting&.company_name

  if params[:phone].present?
   HotspotVoucher.find_by(voucher: params[:voucher]).update(phone: params[:phone])

voucher = HotspotVoucher.find_by(voucher: params[:voucher])
shared_users = HotspotPackage.find_by(name: voucher.package)
   data = build_voucher_sms_data(voucher, params[:phone], shared_users, company_name)
  message = render_hotspot_sms('single', data)

# TenantSmsSenderService.uses_platform?(ActsAsTenant.current_tenant.id)

   
        if ActsAsTenant.current_tenant&.sms_provider_setting&.sms_provider == "Owitech Bulk SMS"

          
TenantSmsSenderService.send_sms(params[:phone], message, ActsAsTenant.current_tenant.id, voucher, 
current_user: current_user)

      # expiration.strftime("%B %d, %Y at %I:%M %p"), 


             elsif ActsAsTenant.current_tenant&.sms_provider_setting&.sms_provider == "SMS leopard"
               send_voucher(params[:phone], params[:voucher],
                shared_users, company_name, current_user
               )
              
            

             elsif ActsAsTenant.current_tenant&.sms_provider_setting&.sms_provider == "TextSms"
               send_voucher_text_sms(params[:phone], params[:voucher],
               shared_users, company_name, current_user
               )



               elsif ActsAsTenant.current_tenant&.sms_provider_setting&.sms_provider == "Talk Sasa"
               send_voucher_talksasa(params[:phone], params[:voucher],
               shared_users, company_name, current_user
               )
             end
         
           return render json: { message: "Voucher sent successfully" }, status: :ok
           
          end
          
end



#   def create

#   if params[:package].blank?
#     render json: { error: "hotspot package is required" }, status: :unprocessable_entity
#     return
#   end

#   if params[:package].blank?
#         render json: { error: "hotspot package is required" }, status: :unprocessable_entity
#         return
#       end
  

#       @hotspot_voucher = HotspotVoucher.new(
#       package: params[:package],
#       shared_users: params[:shared_users],
#       phone: params[:phone],
#     )

      
#     ActivtyLog.create(action: 'create', ip: request.remote_ip,
#  description: "Created hotspot voucher #{@hotspot_voucher.voucher}",
#           user_agent: request.user_agent, user: current_user.username || current_user.email,
#            date: Time.current)

     
#       create_voucher_radcheck(@hotspot_voucher.voucher, @hotspot_voucher.package)
     
#       calculate_expiration(params[:package], @hotspot_voucher)
#         if @hotspot_voucher.save

#           render json: @hotspot_voucher, status: :created

          
#         else
#           render json: @hotspot_voucher.errors, status: :unprocessable_entity 
#         end
    
#   end

def create
  if params[:package].blank?
    render json: { error: "hotspot package is required" }, status: :unprocessable_entity
    return
  end

  hotspot_package = HotspotPackage.find_by(name: params[:package])
  if hotspot_package.nil?
    render json: { error: "Hotspot package '#{params[:package]}' not found" }, status: :unprocessable_entity
    return
  end

  use_radius = router_uses_radius?

  number_of_vouchers = params[:number_of_vouchers].to_i
  number_of_vouchers = 1 if number_of_vouchers < 1

  created_vouchers = []

  ActiveRecord::Base.transaction do
    number_of_vouchers.times do
      voucher_code = generate_voucher_code

      @hotspot_voucher = HotspotVoucher.new(
        package: params[:package],
        shared_users: params[:shared_users],
        phone: params[:phone],
        voucher: voucher_code,
        hotspot_package_id: hotspot_package.id,
        status: 'active',
        sync_status: use_radius ? nil : 'not_synced'
      )

      @hotspot_voucher.save!

      calculate_expiration(params[:package], @hotspot_voucher, @hotspot_voucher.account_id)

      if use_radius
        if ActsAsTenant.current_tenant&.hotspot_setting&.voucher_expiration == 'Real-time expiration'
          create_voucher_radcheck(voucher_code, params[:package], @hotspot_voucher.account_id)
        else
          create_voucher_radcheck_accumulated_sessions(voucher_code, params[:package], @hotspot_voucher.account_id)
        end
      else
        # Native MikroTik account - push the user straight to the router.
        # sync_status/sync_error land on the record so the Sync column
        # and the manual/bulk sync buttons reflect the real state.
        sync_voucher_natively(@hotspot_voucher)
      end

      created_vouchers << @hotspot_voucher
    end

    if number_of_vouchers == 1
      ActivtyLog.create!(
        action: 'create',
        ip: request.remote_ip,
        description: "Created hotspot voucher #{created_vouchers.first.voucher}",
        user_agent: request.user_agent,
        user: current_user.username || current_user.email,
        date: Time.current
      )
    else
      ActivtyLog.create!(
        action: 'create',
        ip: request.remote_ip,
        description: "Created #{created_vouchers.count} hotspot vouchers for package #{params[:package]}",
        user_agent: request.user_agent,
        user: current_user.username || current_user.email,
        date: Time.current
      )
    end
  end

  if created_vouchers.any?
    render json: created_vouchers, status: :created
  else
    render json: { error: "Failed to create vouchers" }, status: :unprocessable_entity
  end

rescue ActiveRecord::RecordInvalid => e
  render json: { error: e.message }, status: :unprocessable_entity
rescue => e
  render json: { error: "An error occurred: #{e.message}" }, status: :unprocessable_entity
end




  def create_voucher_radcheck(hotspot_voucher, package, account_id)

hotspot_package = "hotspot_#{account_id}_#{package.parameterize(separator: '_')}"




radcheck = RadCheck.find_or_initialize_by(username: hotspot_voucher,
account_id: account_id,
radiusattribute: 
'Cleartext-Password')  

radcheck.update!(op: ':=', value: hotspot_voucher)


rad_user_group = RadUserGroup.find_or_initialize_by(username: hotspot_voucher,
 groupname: hotspot_package, priority: 1, account_id: account_id)
rad_user_group.update!(username: hotspot_voucher, groupname: hotspot_package, priority: 1)


validity_period_units = HotspotPackage.find_by(name: package, account_id: account_id).validity_period_units
validity = HotspotPackage.find_by(name: package, account_id: account_id).validity



expiration_time = case validity_period_units
when 'days' then Time.current + validity.days
when 'hours' then Time.current + validity.hours
when 'minutes' then Time.current + validity.minutes
end&.strftime("%d %b %Y %H:%M:%S")

if expiration_time
  rad_check = RadCheck.find_or_initialize_by(username: hotspot_voucher,
   account_id: account_id,
   radiusattribute: 'Expiration')
  rad_check.update!(op: ':=', value: expiration_time)
end
end
  














def create_voucher_radcheck_accumulated_sessions(hotspot_voucher, package, account_id)

hotspot_package = "hotspot_#{account_id}_#{package.parameterize(separator: '_')}"




radcheck = RadCheck.find_or_initialize_by(username: hotspot_voucher,
account_id: account_id,
radiusattribute: 
'Cleartext-Password')  

radcheck.update!(op: ':=', value: hotspot_voucher)


rad_user_group = RadUserGroup.find_or_initialize_by(username: hotspot_voucher,
 groupname: hotspot_package, priority: 1, account_id: account_id)
rad_user_group.update!(username: hotspot_voucher, groupname: hotspot_package, priority: 1)


validity_period_units = HotspotPackage.find_by(name: package, account_id: account_id).validity_period_units
validity = HotspotPackage.find_by(name: package, account_id: account_id).validity



seconds =
  case validity_period_units
  when "minutes"
    validity.minutes.to_i
  when "hours"
    validity.hours.to_i
  when "days"
    validity.days.to_i
  end

if seconds
  rad_check = RadCheck.find_or_initialize_by(username: hotspot_voucher,
   account_id: account_id,
   radiusattribute: 'Expiration')
  rad_check.update!(op: ':=', value: expiration_time)


  radcheck = RadCheck.find_or_initialize_by(
  username: hotspot_voucher,
  account_id: account_id,
  radiusattribute: "Max-All-Session")
   rad_check.update!(
  op: ":=",
  value: seconds
 )
end
end



  def create_voucher_radcheck_compensation(hotspot_voucher, package, 
    account_id)

hotspot_package = "hotspot_#{account_id}_#{package.parameterize(separator: '_')}"




radcheck = RadCheck.find_or_initialize_by(username: hotspot_voucher,
account_id: account_id,
radiusattribute: 
'Cleartext-Password')  

radcheck.update!(op: ':=', value: hotspot_voucher)

rad_user_group = RadUserGroup.find_or_initialize_by(username: hotspot_voucher,
 groupname: hotspot_package, priority: 1, account_id: account_id)
rad_user_group.update!(username: hotspot_voucher, groupname: hotspot_package, priority: 1)


rad_reply = RadReply.find_or_initialize_by(username: hotspot_voucher, 
radiusattribute: '',
account_id: account_id,
 op: ':=', value: '5000')
 
# rad_reply.update!(username: hotspot_voucher, 
# radiusattribute: 'Idle-Timeout', op: ':=', value: '5000')

validity_period_units = HotspotPackage.find_by(name: package, account_id: account_id).validity_period_units
validity = HotspotPackage.find_by(name: package, account_id: account_id).validity

# Step 1: keep as Time object
expiration_time = case validity_period_units
when 'days' then Time.current + validity.days
when 'hours' then Time.current + validity.hours
when 'minutes' then Time.current + validity.minutes
end

# Step 2: add compensation
tenant = Account.find_by(id: account_id)
extra_time = compensation_duration(tenant)

final_expiration = expiration_time + extra_time

# Step 3: convert to string ONLY when saving
formatted_expiration = final_expiration

if final_expiration
  rad_check = RadCheck.find_or_initialize_by(
    username: hotspot_voucher,
    account_id: account_id,
    radiusattribute: 'Expiration'
  )

  rad_check.update!(op: ':=', value: formatted_expiration.strftime("%d %b %Y %H:%M:%S"))
end
  

end












  # PATCH/PUT /hotspot_vouchers/1 or /hotspot_vouchers/1.json
  def update
      @hotspot_voucher = set_hotspot_voucher
    hotspot_package = HotspotPackage.find_by(name: params[:package])
      if @hotspot_voucher.update(
        package: params[:package],
        shared_users: params[:shared_users],
        phone: params[:phone],
        hotspot_package_id: hotspot_package.id

      )
      ActivtyLog.create(action: 'update', ip: request.remote_ip,
 description: "Updated hotspot voucher #{@hotspot_voucher.voucher}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)

          create_voucher_radcheck(@hotspot_voucher.voucher, @hotspot_voucher.package,
           @hotspot_voucher.shared_users, @hotspot_voucher.account_id)

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

  use_radius = router_uses_radius?

  if use_radius
    ActiveRecord::Base.transaction do
      RadCheck.where(username: @hotspot_voucher.voucher).destroy_all
      RadUserGroup.where(username: @hotspot_voucher.voucher).destroy_all
      RadGroupCheck.where(groupname: @hotspot_voucher.voucher).destroy_all
      @hotspot_voucher.destroy!
    end

    ActivtyLog.create(action: 'delete', ip: request.remote_ip,
      description: "Deleted hotspot voucher #{@hotspot_voucher.voucher}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current)

    render json: { message: "Hotspot voucher deleted successfully" }, status: :ok
  else
    mikrotik_result = delete_voucher_natively(@hotspot_voucher)

    ActiveRecord::Base.transaction do
      @hotspot_voucher.destroy!
    end

    ActivtyLog.create(action: 'delete', ip: request.remote_ip,
      description: "Deleted hotspot voucher #{@hotspot_voucher.voucher}",
      user_agent: request.user_agent, user: current_user.username || current_user.email,
      date: Time.current)

    if mikrotik_result[:success]
      render json: { message: "Hotspot voucher deleted successfully" }, status: :ok
    else
      Rails.logger.info "Voucher #{@hotspot_voucher.voucher} deleted locally but MikroTik cleanup failed: #{mikrotik_result[:error]}"
      render json: {
        message: "Hotspot voucher deleted successfully, but could not remove it from the router",
        mikrotik_error: mikrotik_result[:error]
      }, status: :ok
    end
  end
rescue => e
  render json: { error: "Failed to delete voucher: #{e.message}" }, status: :unprocessable_entity
end

 


def sync_to_mikrotik
  @hotspot_voucher = HotspotVoucher.find_by(id: params[:id])
  return render json: { error: 'Voucher not found' }, status: :not_found unless @hotspot_voucher

  sync_voucher_natively(@hotspot_voucher)
  render json: @hotspot_voucher
rescue => e
  render json: { error: "Sync failed: #{e.message}" }, status: :unprocessable_entity
end




def bulk_sync_to_mikrotik
  ids = params[:ids] || params.dig(:hotspot_voucher, :ids) || []
  return render json: { error: 'No vouchers selected' }, status: :unprocessable_entity if ids.empty?

  HotspotVoucher.where(id: ids, account_id: ActsAsTenant.current_tenant.id)
                .update_all(sync_status: 'syncing', sync_error: nil)

  HotspotVoucherBulkSyncJob.perform_later(ActsAsTenant.current_tenant.id, ids)

  render json: { message: "Sync dispatched", queued: ids.size }, status: :accepted
rescue => e
  render json: { error: "Bulk sync failed: #{e.message}" }, status: :unprocessable_entity
end

# def login_with_hotspot_voucher

  

# Rails.logger.info "voucher ip#{params[:ip]}"
  
#   return render json: { error: 'voucher is required' }, status: :bad_request unless params[:voucher].present?

#   # Get client IP
#   client_ip = request.remote_ip

#  host = request.headers['X-Subdomain']
#  account = Account.find_by(subdomain: host)

#   # Find the voucher in the database
#   @hotspot_voucher = HotspotVoucher.find_by(voucher: params[:voucher])
#   return render json: { error: 'Invalid voucher' }, status: :not_found unless @hotspot_voucher


#       if @hotspot_voucher.expiration.present? && @hotspot_voucher.expiration < Time.current
#       return render json: { error: 'Voucher expired' }, status: :forbidden
#     end

#   active_sessions = get_active_sessions(params[:voucher])
# @shared_users = HotspotPackage.find_by(name: @hotspot_voucher.package).shared_users.to_i

  
#   if active_sessions.any?
#     active_voucher_sessions = active_sessions.select { |session| session.include?(params[:voucher]) }
  
#     if active_voucher_sessions.count >= @shared_users
#       return render json: { error: "Voucher is already used by another user, the maximum number of allowed device => #{@shared_users}" }, status: :forbidden
#     end
#   end
  
 
#       nas_routers = NasRouter.where(account_id: account.id)

#       nas_routers.each do |nas_router|
        
#     router_ip_address = nas_router.ip_address
#     router_password = nas_router.password
#     router_username = nas_router.username


#   command = "/ip hotspot active login user=#{params[:voucher]} password=#{params[:voucher]} ip=#{params[:ip]}"

#   begin
#     Net::SSH.start(router_ip_address,  router_username, password: router_password, verify_host_key: :never) do |ssh|
#       output = ssh.exec!(command)
#       if output.include?('failure')
#         return render json: { error: "Login failed: #{output}" }, status: :unauthorized
#       else
#         @hotspot_voucher.update(status: 'used')
#         return render json: {
#           message: 'Connected successfully',
#           device_ip: params[:ip],
#           response: output,
#            username:  @hotspot_voucher.voucher,
#         expiration:  @hotspot_voucher.expiration.strftime("%B %d, %Y at %I:%M %p"),
#         package:  @hotspot_voucher.package
#         }, status: :ok
#       end
#     end
#   rescue Net::SSH::AuthenticationFailed
#     render json: { error: 'SSH authentication failed' }, status: :unauthorized
#   rescue StandardError => e
#     render json: { error: "Failed to log in device", message: e.message }, status: :internal_server_error
#   end
#       end

        
# end
 


def login_with_hotspot_voucher
  return render json: { error: 'voucher is required' }, status: :bad_request unless params[:voucher].present?

  @hotspot_voucher = HotspotVoucher.find_by(voucher: params[:voucher])
  return render json: { error: 'Invalid voucher or username' }, status: :not_found unless @hotspot_voucher

  if @hotspot_voucher.expiration.present? && @hotspot_voucher.expiration < Time.current
    return render json: { error: 'Voucher Or Username expired' }, status: :forbidden
  end

  enable_compensation = ActsAsTenant.current_tenant&.hotspot_customization&.enable_compensation

  if @hotspot_voucher.expiration.nil?
    if enable_compensation
      create_voucher_radcheck_compensation(@hotspot_voucher.voucher,
        @hotspot_voucher.package,
        @hotspot_voucher.account_id)
    end
  end

  if @hotspot_voucher.expiration.nil?
    create_voucher_radcheck(@hotspot_voucher.voucher,
      @hotspot_voucher.package,
      @hotspot_voucher.account_id)
  end

  # get_active_sessions now already filters to just this voucher's sessions,
  # and returns an array of hashes, e.g. [{"user"=>"ABC123", ".id"=>"*1A", ...}]
  active_sessions = get_active_sessions(params[:voucher])
  package = HotspotPackage.find_by(name: @hotspot_voucher.package)

  shared_users = package&.shared_users.to_i

  # no more .select { |s| s.include?(...) } needed — get_active_sessions
  # already returns only sessions matching this voucher
  if active_sessions.count >= shared_users
    return render json: {
      error: "Voucher already used. Max devices allowed: #{shared_users}"
    }, status: :forbidden
  end

  nas_routers = NasRouter.where(account_id: @hotspot_voucher.account_id)

  nas_routers.each do |router|
    begin
      response = RestClient::Request.execute(
        method: :post,
        url: "http://#{router.ip_address}/rest/ip/hotspot/active/login",
        user: router.username,
        password: router.password,
        payload: {
          ip: params[:ip],
          user: params[:voucher],
          password: params[:voucher]
        }.to_json,
        headers: {
          content_type: :json,
          accept: :json
        },
        timeout: 5,       # ← added: stop hanging on a slow/dead router
        open_timeout: 3   # ← added: stop hanging on an unreachable router
      )

      if response.code == 200
        @hotspot_voucher.update!(status: 'used', last_logged_in: Time.now,
          ip: params[:ip], mac: params[:mac], used_voucher: true,
          login_by: 'Voucher Code'
        )

        if @hotspot_voucher.expiration.nil?
          if enable_compensation
            calculate_expiration_login_with_voucher_compensation(package, @hotspot_voucher,
              @hotspot_voucher.account_id)
          end
        end

        if @hotspot_voucher.expiration.nil?
          calculate_expiration_login_with_voucher(package, @hotspot_voucher,
            @hotspot_voucher.account_id)
        end

        return render json: {
          message: 'Connected successfully',
          device_ip: params[:ip],
          username: @hotspot_voucher.voucher,
          expiration: @hotspot_voucher.expiration&.strftime("%B %d, %Y at %I:%M %p"),
          package: @hotspot_voucher.package
        }, status: :ok
      end

    rescue RestClient::Unauthorized
      Rails.logger.info "REST auth failed for router #{router.ip_address}"
      next

    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.info "MikroTik REST error (#{router.ip_address}): #{e.response}"
      next

    rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
      Rails.logger.info "Router #{router.ip_address} timed out during login"
      next

    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
      Rails.logger.info "Router #{router.ip_address} unreachable: #{e.message}"
      next

    rescue StandardError => e
      Rails.logger.info "REST login error: #{e.message}"
      next
    end
  end

  return render json: { error: 'Failed to connect please try again' }, status: :unprocessable_entity
end









  
  private
    def set_hotspot_voucher
      @hotspot_voucher = HotspotVoucher.find_by_id(params[:id])
    end




def calculate_expiration_login(package, voucher_created, account_id)
   hotspot_package = HotspotPackage.find_by(name: package, 
  account_id: account_id)

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
    voucher_created.update(expiration: 
    expiration_time&.strftime("%B %d, %Y at %I:%M %p"),
    # status: 'active'
    )
  end

  # Return both expiration and status
  {
    expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),
    # status: 'active'
  }
end








def calculate_expiration_login_with_voucher(hotspot_package, 
  voucher_created,
   account_id)
  #  hotspot_package = HotspotPackage.find_by(name: package, 
  # account_id: account_id)

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
    voucher_created.update(expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),)
  end

 
  
end



def calculate_expiration_login_with_voucher(hotspot_package,
   voucher_created,
   account_id)
  #  hotspot_package = HotspotPackage.find_by(name: package, 
  # account_id: account_id)
return unless hotspot_package
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
    voucher_created.update(expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),)
  end

  # Return both expiration and status
  {
    expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),
  }
end







def calculate_expiration_login_with_voucher_compensation(hotspot_package,
   voucher_created,
   account_id)
  #  hotspot_package = HotspotPackage.find_by(name: package, 
  # account_id: account_id)

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
tenant = Account.find_by(id: account_id)
extra_time = compensation_duration(tenant)
  final_expiration = expiration_time + extra_time


  # Update status only if expiration is present
  if expiration_time.present?
    voucher_created.update(expiration: final_expiration&.strftime("%B %d, %Y at %I:%M %p"),)
  end

 
end





def calculate_expiration(package, voucher_created, account_id)
  hotspot_package = HotspotPackage.find_by(name: package, 
  account_id: account_id)

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
    voucher_created.update(status: 'active',  expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),)
  else
    status = "unknown" # Handle cases with no expiration logic
  end

  # Return both expiration and status
  {
    expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),
    status: status
  }
end










def calculate_expiration_send_to_customer(package, account_id)
  hotspot_package = HotspotPackage.find_by(name: package, account_id: account_id)

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

    # def generate_voucher_code
    #   voucher_type = HotspotSetting.find_by(voucher_type: 'Mixed').voucher_type
    #   loop do
    #     code = SecureRandom.hex(4).upcase 
    #     break code unless HotspotVoucher.exists?(voucher: code)
    #   end
    # end

def generate_voucher_code
  hotspot_setting = ActsAsTenant.current_tenant&.hotspot_setting
  voucher_type = hotspot_setting&.voucher_type || 'Mixed'

  prefix = hotspot_setting&.voucher_prefix.to_s.strip
  # code_length is the length of the RANDOM portion the user configured
  # (4-16, enforced by HotspotSettingsController#normalized_code_length).
  # The prefix is prepended on top of that.
  code_length = hotspot_setting&.code_length.to_i
  code_length = 8 if code_length <= 0

  # .chars turns the string into an array of single-char strings so
  # .sample (an Array method) actually works — calling .sample directly
  # on a String raised NoMethodError.
  numeric_chars = '0123456789'.chars
  alpha_chars   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.chars
  mixed_chars   = numeric_chars + alpha_chars

  loop do
    random_part =
      case voucher_type
      when 'Numeric'
        Array.new(code_length) { numeric_chars.sample }.join

      when 'Words'
        words = %w[
          SKY NET FAST WIFI DATA ZONE LINK CLOUD
          SPEED HOT SPOT CONNECT
        ]
        raw = "#{words.sample}#{words.sample}"
        if raw.length >= code_length
          raw[0, code_length]
        else
          raw + Array.new(code_length - raw.length) { alpha_chars.sample }.join
        end

      when 'Mixed'
        Array.new(code_length) { mixed_chars.sample }.join

      else
        Array.new(code_length) { mixed_chars.sample }.join
      end

    code = prefix.present? ? "#{prefix}#{random_part}" : random_part

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





def sync_voucher_natively(voucher)
  package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
  return voucher.update(sync_status: 'failed', sync_error: 'Package not found') unless package

  nas = NasRouter.find_by(name: package.nas_router, account_id: voucher.account_id)
  return voucher.update(sync_status: 'failed', sync_error: 'No router specified or router not found') unless nas

  client = RouterosApiClient.new(nas.ip_address, nas.username.to_s, nas.password.to_s, timeout: 10)
  client.connect

  reply = client.talk([
    '/ip/hotspot/user/add',
    "=name=#{voucher.voucher}",
    "=password=#{voucher.voucher}",
    "=profile=#{package.name}"
  ])

  if reply.last.first == '!trap'
    error_message = reply.last.find { |w| w.start_with?('=message=') }&.sub('=message=', '') || 'Unknown MikroTik error'
    voucher.update(sync_status: 'failed', sync_error: error_message)
  else
    voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)
  end

rescue RouterosApiClient::ApiError => e
  voucher.update(sync_status: 'failed', sync_error: e.message)
rescue Errno::ETIMEDOUT, IO::TimeoutError
  voucher.update(sync_status: 'failed', sync_error: "Router #{nas.ip_address} timed out")
rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
  voucher.update(sync_status: 'failed', sync_error: "Router unreachable: #{e.message}")
rescue => e
  voucher.update(sync_status: 'failed', sync_error: e.message)
ensure
  client&.close
end

def sync_voucher_natively_realtime_expiration(voucher)
  package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
  return voucher.update(sync_status: 'failed', sync_error: 'Package not found') unless package

  nas = NasRouter.find_by(name: package.nas_router)
  return voucher.update(sync_status: 'failed', sync_error: 'No router specified or router not found') unless nas

  client = RouterosApiClient.new(nas.ip_address, nas.username.to_s, nas.password.to_s, timeout: 10)
  client.connect

  reply = client.talk([
    '/ip/hotspot/user/add',
    "=name=#{voucher.voucher}",
    "=password=#{voucher.voucher}",
    "=profile=#{package.name}",
    "=limit-uptime=#{validity_for_mikrotik(package)}"
  ])

  if reply.last.first == '!trap'
    error_message = reply.last.find { |w| w.start_with?('=message=') }&.sub('=message=', '') || 'Unknown MikroTik error'
    voucher.update(sync_status: 'failed', sync_error: error_message)
  else
    voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)
  end

rescue RouterosApiClient::ApiError => e
  voucher.update(sync_status: 'failed', sync_error: e.message)
rescue Errno::ETIMEDOUT, IO::TimeoutError
  voucher.update(sync_status: 'failed', sync_error: "Router #{nas.ip_address} timed out")
rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
  voucher.update(sync_status: 'failed', sync_error: "Router unreachable: #{e.message}")
rescue => e
  voucher.update(sync_status: 'failed', sync_error: e.message)
ensure
  client&.close
end


def mikrotik_error_message(e)
  return e.message unless e.response
  body = e.response.body.to_s
  parsed = JSON.parse(body) rescue nil
  return body.presence || e.message unless parsed
  parsed['detail'] || parsed['message'] || parsed['error'] || body
end
















def validity_for_mikrotik(pkg)
  case pkg.validity_period_units
  when "minutes"
    "#{pkg.validity}m"
  when "hours"
    "#{pkg.validity}h"
  when "days"
    "#{pkg.validity}d"
  when "weeks"
    "#{pkg.validity}w"
  else
    "0s"
  end
end


# def delete_voucher_natively(voucher)
#   package = HotspotPackage.find_by(
#     name: voucher.package,
#     account_id: voucher.account_id
#   )

#   nas = NasRouter.find_by(name: package&.nas_router)

#   return {
#     success: false,
#     error: "No router specified or router not found"
#   } unless nas

#   begin
#     base_url = "http://#{nas.ip_address}/rest/ip/hotspot/user"

#     # ---------------------------------------------------------
#     # 1. Disconnect active session first
#     # ---------------------------------------------------------
#     active_sessions = get_active_sessions(voucher.voucher)

#     active_sessions.to_a.each do |session|
#       session_id = session[".id"]
#       next unless session_id.present?

#       encoded_session_id =
#         URI::DEFAULT_PARSER.escape(session_id.to_s)

#       RestClient::Request.execute(
#         method: :delete,
#         url: "http://#{nas.ip_address}/rest/ip/hotspot/active/#{encoded_session_id}",
#         user: nas.username.to_s,
#         password: nas.password.to_s,
#         timeout: 5,
#         open_timeout: 3
#       )
#     end

#     # ---------------------------------------------------------
#     # 2. Get all hotspot users
#     # ---------------------------------------------------------
#     response = RestClient::Request.execute(
#       method: :get,
#       url: base_url,
#       user: nas.username.to_s,
#       password: nas.password.to_s,
#       headers: {
#         accept: :json
#       },
#       timeout: 10,
#       open_timeout: 5
#     )

#     users = JSON.parse(response.body)

#     # ---------------------------------------------------------
#     # 3. Find the MikroTik user by voucher name
#     # ---------------------------------------------------------
#     hotspot_user = users.find do |user|
#       user["name"].to_s == voucher.voucher.to_s
#     end

#     # User doesn't exist on MikroTik anymore
#     return { success: true } unless hotspot_user

#     # ---------------------------------------------------------
#     # 4. Get MikroTik internal resource ID
#     # ---------------------------------------------------------
#     user_id = hotspot_user[".id"]

#     unless user_id.present?
#       return {
#         success: false,
#         error: "MikroTik hotspot user found but has no .id"
#       }
#     end

#     Rails.logger.info(
#       "Deleting MikroTik hotspot user '#{voucher.voucher}' with .id=#{user_id}"
#     )

#     # ---------------------------------------------------------
#     # 5. Delete using MikroTik .id
#     # ---------------------------------------------------------
#     encoded_user_id =
#       URI::DEFAULT_PARSER.escape(user_id.to_s)

#     RestClient::Request.execute(
#       method: :delete,
#       url: "#{base_url}/#{encoded_user_id}",
#       user: nas.username.to_s,
#       password: nas.password.to_s,
#       headers: {
#         content_type: :json
#       },
#       timeout: 5,
#       open_timeout: 3
#     )

#     { success: true }

#   rescue RestClient::NotFound
#     # Already deleted from MikroTik
#     { success: true }

#   rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
#     {
#       success: false,
#       error: "Router #{nas.ip_address} timed out"
#     }

#   rescue Errno::ECONNREFUSED,
#          Errno::EHOSTUNREACH,
#          SocketError => e
#     {
#       success: false,
#       error: "Router #{nas.ip_address} unreachable: #{e.message}"
#     }

#   rescue RestClient::ExceptionWithResponse => e
#     {
#       success: false,
#       error: e.response&.body.presence || e.message
#     }

#   rescue => e
#     {
#       success: false,
#       error: e.message
#     }
#   end
# end





def delete_voucher_natively(voucher)
  package = HotspotPackage.find_by(
    name: voucher.package,
    account_id: voucher.account_id
  )

  nas = NasRouter.find_by(name: package&.nas_router)

  return {
    success: false,
    error: "No router specified or router not found"
  } unless nas

  client = RouterosApiClient.new(nas.ip_address, nas.username.to_s, nas.password.to_s, timeout: 10)
  client.connect

  # ---------------------------------------------------------
  # 1. Disconnect active session(s) first
  # ---------------------------------------------------------
  active_sessions = get_active_sessions(voucher.voucher)

  active_sessions.to_a.each do |session|
    session_id = session[".id"]
    next unless session_id.present?

    client.talk(['/ip/hotspot/active/remove', "=.id=#{session_id}"])
  end

  # ---------------------------------------------------------
  # 2. Find the MikroTik user by voucher name
  # ---------------------------------------------------------
  reply = client.talk(['/ip/hotspot/user/print', "?name=#{voucher.voucher}"])
  user_sentence = reply.find { |s| s.first == '!re' }

  # User doesn't exist on MikroTik anymore
  unless user_sentence
    return { success: true }
  end

  user_id = user_sentence.find { |w| w.start_with?('=.id=') }&.sub('=.id=', '')

  unless user_id.present?
    return {
      success: false,
      error: "MikroTik hotspot user found but has no .id"
    }
  end

  Rails.logger.info(
    "Deleting MikroTik hotspot user '#{voucher.voucher}' with .id=#{user_id}"
  )

  # ---------------------------------------------------------
  # 3. Delete using MikroTik .id
  # ---------------------------------------------------------
  remove_reply = client.talk(['/ip/hotspot/user/remove', "=.id=#{user_id}"])

  if remove_reply.last.first == '!trap'
    error_message = remove_reply.last.find { |w| w.start_with?('=message=') }&.sub('=message=', '') || 'Unknown MikroTik error'
    { success: false, error: error_message }
  else
    { success: true }
  end

rescue RouterosApiClient::ApiError => e
  { success: false, error: e.message }
rescue Errno::ETIMEDOUT, IO::TimeoutError
  { success: false, error: "Router #{nas.ip_address} timed out" }
rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
  { success: false, error: "Router #{nas.ip_address} unreachable: #{e.message}" }
rescue => e
  { success: false, error: e.message }
ensure
  client&.close
end




def router_uses_radius?
  return true unless ActsAsTenant.current_tenant
  setting = NasSetting.find_by(account_id: ActsAsTenant.current_tenant.id )
  setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
end



def router_uses_radius_payment(account_id)
  setting = NasSetting.find_by(account_id: account_id)
  setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
end




def mikrotik_add_binding_direct(binding, nas)
  require 'net/ssh'
  mac = binding.mac.upcase.gsub('-', ':')
  cmd = "/ip hotspot ip-binding add mac-address=\"#{mac}\" type=bypassed server=hotspot1"
  cmd += " comment=\"#{binding.name}\"" if binding.name.present?

  Net::SSH.start(nas.ip_address, nas.username,
    password: nas.password.to_s, verify_host_key: :never,
    non_interactive: true, timeout: 15
  ) { |ssh| ssh.exec!(cmd) }
end



def mikrotik_add_queue_direct(binding, package, nas)
  return unless binding.ip.present? && package.upload_limit.present?
  require 'net/ssh'

  queue_name = "binding_#{binding.mac.upcase.gsub(':', '')}"
  cmd = "/queue simple add name=\"#{queue_name}\" target=\"#{binding.ip}\" " \
        "max-limit=\"#{package.upload_limit}M/#{package.download_limit}M\" " \
        "comment=\"device_binding_#{binding.id}\""

  Net::SSH.start(nas.ip_address, nas.username,
    password: nas.password.to_s, verify_host_key: :never,
    non_interactive: true, timeout: 15
  ) { |ssh| ssh.exec!(cmd) }
end







      def compensation_duration(tenant)
  customization = tenant.hotspot_customization

  return 0 unless customization&.enable_compensation

  if customization.compensation_minutes.present?
    customization.compensation_minutes.to_i.minutes
  elsif customization.compensation_hours.to_i.present?
    customization.compensation_hours.hours
  else
    0
  end
end




      def format_bytes(bytes)
      units = ['B', 'KB', 'MB', 'GB', 'TB']
      return '0 B' if bytes.zero?
    
      exp = (Math.log(bytes) / Math.log(1024)).to_i
      size = bytes / (1024.0**exp)
      "%.2f #{units[exp]}" % size
    
    
  end




  def format_uptime(seconds)
  return '0s' if seconds.nil?

  mm, ss = seconds.divmod(60)
  hh, mm = mm.divmod(60)
  dd, hh = hh.divmod(24)

  parts = []
  parts << "#{dd}d" if dd > 0
  parts << "#{hh}h" if hh > 0
  parts << "#{mm}m" if mm > 0
  parts << "#{ss}s"
  parts.join(' ')
    end





    def send_voucher(phone_number, voucher_code, shared_users, company_name, current_user)
  voucher = HotspotVoucher.find_by(voucher: voucher_code)
  voucher.update(sms_sent: true)

  data = build_voucher_sms_data(voucher, phone_number, shared_users, company_name)
  original_message = render_hotspot_sms('single', data)   # ← was the hardcoded string

  api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
  api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
  sender_id = "SMS_TEST"

  uri = URI("https://api.smsleopard.com/v1/sms/send")
  params = {
    username: api_key, password: api_secret,
    message: original_message, destination: phone_number, source: sender_id
  }
  uri.query = URI.encode_www_form(params)
  response = Net::HTTP.get_response(uri)

  if response.is_a?(Net::HTTPSuccess)
    sms_data = JSON.parse(response.body)
    sms_recipient = sms_data['recipients'][0]['number']
    sms_status = sms_data['recipients'][0]['status']

    SystemAdminSm.create!(
      user: sms_recipient, message: original_message, status: sms_status,
      date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
      system_user: current_user.username, sms_provider: 'SMS leopard'
    )
  else
    Rails.logger.info "Failed to send message: #{response.body}"
  end
end

             


           def send_voucher_text_sms(phone_number, voucher_code,
             shared_users, company_name, current_user
            )
  # Was previously receiving the voucher code in a param literally named
  # `voucher`, but the body referenced an undefined `voucher_code` — a
  # guaranteed NameError on every call. Renamed the param to match, and
  # look up the actual HotspotVoucher record before using it, same as
  # the SMS Leopard sender above (build_voucher_sms_data needs the
  # record, not the bare code string).
  hotspot_voucher = HotspotVoucher.find_by(voucher: voucher_code)
  unless hotspot_voucher
    Rails.logger.info "send_voucher_text_sms: voucher #{voucher_code} not found"
    return
  end


  hotspot_voucher.update(sms_sent: true)

  sms_setting = SmsSetting.find_by(sms_provider: 'TextSms')

  # if sms_setting.nil?
  #   render json: { error: "SMS provider not found" }, status: :not_found
  #   return
  # end

  api_key = sms_setting&.api_key
  partnerID = sms_setting&.partnerID 
   shortcode = sms_setting.sender_id

  sms_template = ActsAsTenant.current_tenant.sms_template
  send_voucher_template = sms_template&.send_voucher_template





  Rails.logger.info "API KEY: #{api_key.inspect}"
Rails.logger.info "PARTNER ID: #{partnerID.inspect}"
Rails.logger.info "SHORTCODE: #{shortcode.inspect}"
Rails.logger.info "PHONE: #{phone_number.inspect}"

  # original_message = if sms_template
  #   MessageTemplate.interpolate(send_voucher_template, { voucher_code: voucher_code })
  # else
  #   "Your voucher code: #{voucher_code} for #{shared_users} devices. This code is valid until #{voucher_expiration}.
  #    Enjoy your browsing"
  # end

    # original_message = "Your voucher code is: #{voucher_code}. This code is valid until #{voucher_expiration}.


    data = build_voucher_sms_data(hotspot_voucher, phone_number, shared_users, company_name)
original_message = render_hotspot_sms('single', data)

  uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
  params = {
    apikey: api_key,
    message: original_message,
    mobile: phone_number,
    partnerID: partnerID,
    shortcode: shortcode
  }

Rails.logger.info "MESSAGE: #{original_message}"

  uri.query = URI.encode_www_form(params)

  response = Net::HTTP.get_response(uri)

  if response.is_a?(Net::HTTPSuccess)
    sms_data = JSON.parse(response.body)

      sms_recipient = sms_data['responses'][0]['mobile']
      sms_status = sms_data['responses'][0]['response-description']

       Rails.logger.info  "Recipient: #{sms_recipient}, Status: #{sms_status}"

      # Save the message and response details in your database
     
 SystemAdminSm.create!(
        user: sms_recipient,
        message: original_message,
        status: sms_status,
        date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
        system_user: current_user.username,
        sms_provider: 'Text Sms')
    
      # render json: { error: "Failed to send message: #{sms_data['responses'][0]['response-description']}" }
       Rails.logger.info "sent message: #{sms_data['responses'][0]['response-description']}"
       
    
  else
    puts "Failed to send message: #{response.body}"
    # render json: { error: "Failed to send message: #{response.body}" }
  end
end








 def send_voucher_talksasa(phone_number, voucher_code,
                          shared_users, company_name, current_user)

                          formatted_phone_number = "254#{phone_number.gsub(/\A0/, '')}"
  # Same fix as send_voucher_text_sms above: the param was named `voucher`
  # while the body referenced the undefined `voucher_code` — renamed the
  # param so the existing lookup below actually resolves.
  HotspotVoucher.find_by(voucher: voucher_code)&.update(sms_sent: true)
  voucher = HotspotVoucher.find_by(voucher: voucher_code)

  sms_setting = SmsSetting.find_by(sms_provider: 'Talk Sasa')

  api_key  = sms_setting&.api_key
  sender_id = sms_setting&.sender_id

  sms_template = ActsAsTenant.current_tenant.sms_template
  send_voucher_template = sms_template&.send_voucher_template
data = build_voucher_sms_data(voucher, phone_number, shared_users, company_name)
original_message = render_hotspot_sms('single', data)


  uri = URI.parse("https://bulksms.talksasa.com/api/v3/sms/send")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.request_uri)

  request["Authorization"] = "Bearer #{api_key}"
  request["Content-Type"] = "application/json"
  request["Accept"] = "application/json"

  request.body = {
    recipient: formatted_phone_number,
    sender_id: sender_id,
    type: "plain",
    message: original_message
  }.to_json

  response = http.request(request)

  Rails.logger.info "TalkSasa Response: #{response.body}"

  if response.is_a?(Net::HTTPSuccess)
    sms_data = JSON.parse(response.body)

    first_response = sms_data['responses']&.first

    sms_recipient = first_response&.dig('mobile')
    sms_status    = sms_data['status']

    Rails.logger.info "sms data =>: #{sms_data}, Status: #{sms_status}"

    SystemAdminSm.create!(
      user: phone_number,
      message: original_message,
      status: sms_status,
      date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
      system_user: current_user.username,
      sms_provider: 'Talk Sasa'
    )

    Rails.logger.info "Sent message successfully with talk sasa"
  else
    Rails.logger.info "Failed to send SMS: #{response.code} - #{response.body}"
    SystemAdminSm.create!(
      user: phone_number,
      message: original_message,
      status: sms_status,
      date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
      system_user: current_user.username,
      sms_provider: 'Talk Sasa'
    )
  end
end





def mikrotik_add_queue_for_tv_plan(binding, tv_plan, nas)
  return unless binding.ip.present? && tv_plan&.upload_limit.present?
  require 'net/ssh'

  queue_name = "binding_#{binding.mac.upcase.gsub(':', '')}"
  cmd = "/queue simple add name=\"#{queue_name}\" target=\"#{binding.ip}\" " \
        "max-limit=\"#{tv_plan.upload_limit}M/#{tv_plan.download_limit}M\" " \
        "comment=\"tv_plan_#{binding.id}\""

  Net::SSH.start(nas.ip_address, nas.username,
    password: nas.password.to_s, verify_host_key: :never,
    non_interactive: true, timeout: 15
  ) { |ssh| ssh.exec!(cmd) }
end














def tv_plan_expiration(tv_plan)
  seconds =
    case tv_plan.validity_period_units.to_s.downcase
    when 'minutes' then tv_plan.validity.to_i.minutes
    when 'hours'   then tv_plan.validity.to_i.hours
    when 'days'    then tv_plan.validity.to_i.days
    else 0.seconds
    end

  (Time.current + seconds).strftime("%Y-%m-%d %H:%M:%S")
end


def get_active_sessions(voucher)
  nas_routers = NasRouter.where(account_id: ActsAsTenant.current_tenant.id)
  all_matching_sessions = []

  nas_routers.each do |nas_router|
    begin
      response = RestClient::Request.execute(
        method: :get,
        url: "http://#{nas_router.ip_address}/rest/ip/hotspot/active",
        user: nas_router.username,
        password: nas_router.password,
        timeout: 5,       # read timeout - how long to wait for a response
        open_timeout: 3   # connection timeout - how long to wait to even connect
      )

      users = JSON.parse(response.body)
      matching = users.select { |u| u["user"] == voucher }

      if matching.any?
        Rails.logger.info "Found #{matching.count} active session(s) for voucher #{voucher} on router #{nas_router.ip_address}"
        all_matching_sessions.concat(matching)
      end

    rescue RestClient::Unauthorized
      Rails.logger.error "REST auth failed for router #{nas_router.ip_address}"
      next

    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "MikroTik REST error on #{nas_router.ip_address}: #{e.response}"
      next

    rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
      Rails.logger.error "Timed out reaching router #{nas_router.ip_address} for active sessions"
      next

    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
      Rails.logger.error "Router #{nas_router.ip_address} unreachable: #{e.message}"
      next

    rescue StandardError => e
      Rails.logger.error "Failed to get active sessions from #{nas_router.ip_address}: #{e.message}"
      next
    end
  end

  all_matching_sessions
end







# private section, near the other sms senders

def build_voucher_sms_data(voucher, phone_number, shared_users, company_name)
  package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)

  {
    customer_phone: phone_number,
    plan_name: package&.name,
    voucher_code: voucher.voucher,
    username: voucher.voucher,
    password: voucher.voucher,
    validity: voucher.expiration&.strftime("%B %d, %Y at %I:%M %p"),
    price: package&.price,
    company_name: company_name,
    voucher_count: shared_users,
    voucher_list: HotspotSmsTemplate.format_voucher_list(
      [{ code: voucher.voucher, username: voucher.voucher, password: voucher.voucher }]
    )
  }
end

# group is 'single' because these methods send exactly one voucher code
# to one phone number. If you later build a bulk "send N vouchers to one
# number" flow, call render_hotspot_sms('multi', data) from there instead.
def render_hotspot_sms(group, data)
  template = HotspotSmsTemplate.active_for(ActsAsTenant.current_tenant.id, group)
  return default_hotspot_sms_message(group, data) unless template

  template.render(data)
end

def default_hotspot_sms_message(group, data)
  if group == 'multi'
    "Your voucher codes:\n#{data[:voucher_list]}\nValid for: #{data[:validity]}. Enjoy your browsing (FROM: #{data[:company_name]})"
  else
    "Your voucher code is: #{data[:voucher_code]}. Enjoy your browsing (FROM: #{data[:company_name]})"
  end
end






def send_tv_plan_confirmation_sms(binding, tv_plan, session)
  return unless session.phone_number.present?

  data = {
    customer_phone: session.phone_number,
    device_name:    binding.name,
    plan_name:      tv_plan&.name,
    price:          tv_plan&.price,
    validity:       binding.expiry&.to_s,
    portal_url:     hotspot_portal_url(session.account_id),
    company_name:   ActsAsTenant.current_tenant&.company_setting&.company_name
  }

  template = HotspotSmsTemplate.active_for(session.account_id, 'tv_plan_purchase')
  message = template ? template.render(data) : default_tv_plan_sms(data)

  provider = ActsAsTenant.current_tenant&.sms_provider_setting&.sms_provider
  case provider
  when 'SMS leopard'   then send_sms_leopard_raw(session.phone_number, message)
  when 'TextSms'       then send_textsms_raw(session.phone_number, message)
  when 'Talk Sasa'     then send_talksasa_raw(session.phone_number, message)
  end
rescue => e
  Rails.logger.error "send_tv_plan_confirmation_sms failed: #{e.message}"
end


def default_tv_plan_sms(data)
  "Payment received! Your #{data[:plan_name]} plan for #{data[:device_name]} is active until #{data[:validity]}. " \
  "Manage devices: #{data[:portal_url]} (login with this phone number). — #{data[:company_name]}"
end

# Build the portal URL for the customer's tenant — adjust the default
# platform domain / account->domain mapping to match how you already
def hotspot_portal_url(account_id)
  account = Account.find_by(id: account_id)
  return nil unless account

  platform_domain = account.respond_to?(:platform_domain) && account.platform_domain.present? ? account.platform_domain : 'aitechs.co.ke'
  "https://#{account.subdomain}.#{platform_domain}/hotspot-customer-portal"
end

end