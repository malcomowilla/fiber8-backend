class HotspotVouchersController < ApplicationController
  # before_action :set_hotspot_voucher, only: %i[ show edit update destroy ]

load_and_authorize_resource except: [:login_with_hotspot_voucher,
 :make_payment, :check_payment_status, :payment_and_conected_status,
 :stk_push_status, :transaction_status_result,:login_with_receipt_number,
 :receipt_number_status

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
    @account = Account.find_by(subdomain: host)
  @hotspot_vouchers = Rails.cache.fetch("hotspot_vouchers_#{@account.id}_index", expires_in: 2.seconds) do
    HotspotVoucher.order(created_at: :desc).to_a
  end
  render json: @hotspot_vouchers
  #  @hotspot_vouchers = HotspotVoucher.order(created_at: :desc)
  # render json: @hotspot_vouchers
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

  # active_status = HotspotVoucher.find_or_create_by(phone: customer_phone_number,
  #  status: 'active')
      hotspot_mpesa_revenue = HotspotMpesaRevenue.find_or_create_by(
              reference: receipt_no,

     )
     hotspot_mpesa_revenue.update(

      amount: amount,
      voucher: active_session.voucher_code,
      payment_method: "Mpesa",
      time_paid: finalised_time,
      # hotspot_voucher_id: active_session.hotspot_voucher_id,
      name: customer_name,
      # login_by: 'Mpesa Transaction',
      account_id: active_session.account_id,
     )
     hotspot_mpesa_revenue.save!


  voucher = HotspotVoucher.find_or_create_by(
      voucher: active_session.voucher_code,


)
voucher.update(
  package: active_session.hotspot_package,
  phone: active_session.phone_number,
  
  ip: active_session.ip,
account_id: active_session.account_id)
voucher.save!

    #  Rails.logger.info "Hotspot Mpesa Revenue => #{hotspot_mpesa_revenue}"

     create_voucher_radcheck(active_session.voucher_code,
      active_session.hotspot_package, 
active_session.account_id)
calculate_expiration(active_session.hotspot_package, voucher,
 active_session.account_id)


hotspot_mpesa_revenue.update(hotspot_voucher_id: voucher.id)
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
 
   


       active_session.update(
        paid: true, connected: true
       )

     
    end

  rescue RestClient::Unauthorized
    Rails.logger.info "REST auth failed for router #{nas.ip_address}"

  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "MikroTik REST error on #{nas.ip_address}: #{e.response}"

  rescue StandardError => e
    Rails.logger.info "REST error logging in device #{active_status.ip}: #{e.message}"
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
  return render json: { error: 'Transaction does not exist' }, status: :not_found
end

# Safely check expiration through the association
if mpesa_revenue.hotspot_voucher&.expiration.present? && 
   mpesa_revenue.hotspot_voucher.expiration < Time.current
  return render json: { error: 'Session expired for voucher or username' }, status: :forbidden
end


  if transaction_status_query[:success]
    
present_voucher_or_username = HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.expiration.present?


nas_routers = NasRouter.where(account_id: HotspotMpesaRevenue.find_by(reference: transaction_id).account_id)

if present_voucher_or_username
  voucher_code = HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.voucher

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
 


#  username: @hotspot_voucher.voucher,
#           expiration: @hotspot_voucher.expiration&.strftime("%B %d, %Y at %I:%M %p"),
#           package: @hotspot_voucher.package

   HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.update!(status: "used", 
      last_logged_in: Time.now,
       ip: HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.ip, used_voucher: true)

       package = HotspotPackage.find_by(name: HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.package)
       expiration_time = HotspotMpesaRevenue.find_by(reference: transaction_id).hotspot_voucher.expiration
       TemporarySession.find_by(ip: ip).update(paid: true, connected: true)
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
    Rails.logger.info "REST error logging in device #{active_status.ip}: #{e.message}"
  end
end


end

    
  else
    render json: { error: 'Failed to fetch transaction status' }, status: :unprocessable_entity
  end

end






  def hotspot_traffic
  # Cache key that includes timestamp for time-based invalidation
  cache_key = "hotspot_traffic_#{Time.current.beginning_of_minute.to_i}"
  
  # Use cache with 10-second expiration (adjust based on your needs)
  hotspot_data = Rails.cache.fetch(cache_key, expires_in: 10.seconds) do
    total_bytes = 0
    total_bytes_upload_download = 0
    total_bytes_upload = 0
    total_bytes_download = 0

    # Get active sessions within last 3 minutes
    active_sessions_upload_download = RadAcct.where(
      acctstoptime: nil, 
      framedprotocol: ''
    ).where('acctupdatetime > ?', 3.minutes.ago)
    
    active_sessions = RadAcct.where(
      acctstoptime: nil,
      framedprotocol: ""
    ).where('acctupdatetime > ?', 3.minutes.ago)

    # Calculate upload/download totals
    active_sessions_upload_download.each do |session|
      download_bytes = session.acctinputoctets || 0
      upload_bytes = session.acctoutputoctets || 0
      total_bytes_download += download_bytes
      total_bytes_upload += upload_bytes
      session_total = download_bytes + upload_bytes
      total_bytes_upload_download += session_total
    end

    # Prepare user data
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

    # Return the data to be cached
    {
      active_user_count: active_user_data.size,
      total_upload: format_bytes(total_bytes_upload),
      total_download: format_bytes(total_bytes_download),
      total_bandwidth: format_bytes(total_bytes_upload_download),
      users: active_user_data,
      timestamp: Time.current.iso8601,
      cache_hit: false # Flag to indicate this is fresh data
    }
  end
  
  # Update cache hit flag if this is a cache hit
  hotspot_data[:cache_hit] = true unless hotspot_data[:cache_hit]
  
  render json: hotspot_data
end


  






def check_payment_status
  raw_body = request.body.read

# Rails.logger.info "Parsed data calback mpesa: #{request.body.read}"
Rails.logger.info "Parsed data callback mpesa: #{raw_body}"

  # data = JSON.parse(request.body.read) rescue {}
  data = JSON.parse(raw_body) rescue {}
  bill_ref = data["BillRefNumber"]

  if bill_ref.start_with?("hotspot_")
    # Remove "hotspot_" prefix and extract session_id and voucher_code
    parts = bill_ref.sub("hotspot_", "").split("_")
    session_id = parts[0]
    voucher_code = parts[1]
        session = TemporarySession.find_by(session: session_id, 
        )

        # voucher = HotspotVoucher.find_by(voucher: voucher_code)

        voucher = HotspotVoucher.create!(
  package: session.hotspot_package,
  phone: session.phone_number,
  voucher: session.voucher_code,
  mac: session.mac,
  ip: session.ip,
  checkout_request_id: session.checkout_request_id,
account_id: session.account_id,

)
session.update(hotspot_voucher_id: voucher.id)
    
create_voucher_radcheck(voucher_code, session.hotspot_package, 
session.account_id)

calculate_expiration(session.hotspot_package, voucher, session.account_id)

SendSmsHotspotService.send_sms(voucher.voucher, data)

nas_routers = NasRouter.where(account_id: session.account_id)
nas_routers.each do |nas|
  begin
    response = RestClient::Request.execute(
      method: :post,
      url: "http://#{nas.ip_address}/rest/ip/hotspot/active/login",
      user: nas.username,
      password: nas.password,
      payload: {
        ip: session.ip,
        user: voucher_code,
        password: voucher_code
      }.to_json,
      headers: {
        content_type: :json,
        accept: :json
      }
    )

    if response.code == 200
      Rails.logger.info "Device #{session.ip} successfully logged 
    in with voucher #{voucher_code} on router #{nas.ip_address}"
      session.update!( connected: true, status: 'used')


      voucher.update!(status: "used", last_logged_in: Time.now,
       used_voucher: true)

      # SendSmsHotspotJob.perform_now(voucher.voucher, data)
      # HotspotNotificationsChannel.broadcast_to(
      #   session.ip,
      #   message: "Payment received! You are now connected."
      # )
    end

  rescue RestClient::Unauthorized
    Rails.logger.info "REST auth failed for router #{nas.ip_address}"

  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "MikroTik REST error on #{nas.ip_address}: #{e.response}"

  rescue StandardError => e
    Rails.logger.info "REST error logging in device #{session.ip}: #{e.message}"
  end
end



elsif data["BillRefNumber"].starts_with?("INV")

bill_ref = data["BillRefNumber"]
paid_amount = data["TransAmount"].to_i

invoice = Invoice.where(invoice_number: bill_ref,
status: "unpaid"
).first

if invoice.total == bill_ref
invoice.update!(status: 'paid', 
           amount_paid: paid_amount,
           total: data["TransAmount"]
           )

      hotspot_plan = HotspotAndDialPlan.find_by(account_id: invoice.account_id,

      )
      hotspot_plan.update(
      
      status: "active",
     
      expiry: Time.current + 30.days,
      )

end


  else

 bill_ref = data["BillRefNumber"]

  # subscriber_account_number = Subscriber.find_by(ref_no:  bill_ref).ref_no
  
  found_subscriber = Subscriber.find_by(ref_no:  bill_ref)
  nas_routers = NasRouter.where(account_id: found_subscriber.account_id)
        subscription = Subscription.find_by(id: found_subscriber.id, 
        account_id: found_subscriber.account_id)
paid_amount = data["TransAmount"].to_i
          invoice = SubscriberInvoice
  .where(
    subscriber_id: found_subscriber.id,
    account_id: found_subscriber.account_id,
    status: "unpaid"
  )
  .order(:invoice_date)
  .first

        
  subscriber_phone_number = Subscriber.find_by(id: subscription.subscriber_id).phone_number
        # package_amount_paid = data["TransAmount"]
  expiration_time = Time.parse(subscription.expiration_date.to_s)


        # expiration_time > Time.current
        # paid_right_amount = Package.find_by(
        #   account_id: subscription.account_id,
        #   amount: package_amount_paid
        # )

       invoice.update!(status: 'paid', description: "Invoice paid for
           wifi package => #{subscription.package_name}",
           
           amount: paid_amount,
           )

           subscription.update(invoice_expired_created_at:  nil)

# company_name, account_no, tenant
company_name = CompanySetting.find_by(account_id: invoice.account_id)
send_invoice_paid_notification = SubscriberSetting.find_by(account_id: 21).invoice_created_or_paid

          if send_invoice_paid_notification
        SendInvoicePaidJob.perform_now(
          company_name.company_name,
          bill_ref,
          invoice.account,
          subscriber_phone_number
        )
          end


        if invoice.amount.to_s === data["TransAmount"]

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
      # rescue StandardError => e
      #   Rails.logger.error "Error removing PPPoE connection for username #{subscription.ppoe_username}: #{e.message}"
      # end


end
        

   

    pppoe_revenue = PpPoeMpesaRevenue.create(
      amount: data["TransAmount"],
      payment_method: "Mpesa",
      time_paid: data["TransTime"],
      account_number:  bill_ref,
      reference: data["TransID"],
      customer_name: data['FirstName'],
      payment_type: "Deposit",
      account_id: invoice.account_id,
      subscriber_id: subscription.subscriber_id

    )
     SubscriberTransaction.create!(
            type: 'Deposit',
            credit: pppoe_revenue.credit,
            debit: pppoe_revenue.amount,
            date:  pppoe_revenue.time_paid,
            title:  pppoe_revenue.reference,
            description: 'Payment made via M-Pesa',
            account_id:  pppoe_revenue.account_id,
            subscriber_id: pppoe_revenue.subscriber_id
          )

      SubscriberWalletBalance.create(
        subscriber_id: pppoe_revenue.subscriber_id,
        amount: pppoe_revenue.amount,
        account_id: pppoe_revenue.account_id
      )
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




def stk_push_status
    shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.short_code
  passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.passkey
  consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_key
  consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_secret
 checkout_request_id = params[:checkout_request_id]
Rails.logger.info "checkout_request_id: #{checkout_request_id}"
  stk_push_query = StkStatusService.initiate_stk_query(
    shortcode,  passkey,
    consumer_key, consumer_secret,checkout_request_id
  )

  if stk_push_query[:success]
    stk_push_query_response = stk_push_query[:response]
    render json: { success: true, response: stk_push_query_response }
  else
    render json: { error: 'Failed to fetch stk push status'}
  end


end




def receipt_number_status
 active_session = TemporarySession.find_by(ip: params[:ip])
 if active_session
  render json: { paid: active_session.paid, connected: active_session.connected }
 else
  render json: { paid: false, connected: false }
 end
end




def make_payment
host = request.headers['X-Subdomain']
  phone_number = params[:phone_number]
  amount = params[:amount]
  shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.short_code
  passkey = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.passkey
  consumer_key = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_key
  consumer_secret = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.consumer_secret

  voucher_code = generate_voucher_code
#   session_id = rand(100000..999999).to_s
# TemporarySession.create!(
#   session: session_id,
#   ip: params[:ip],    
# )

session_id = rand(100000..999999).to_s

session = TemporarySession.find_or_initialize_by(ip: params[:ip],
session: session_id,
paid: false, 
connected: false,
hotspot_package: params[:package],
voucher_code: voucher_code,
phone_number: phone_number

)
session.update(status: 'pending')
# session.session   = session_id
# session.paid      = false
# session.connected = false

session.save!

      hotspot_payment = MpesaService.initiate_stk_push(phone_number, 
      amount,
       shortcode,  passkey,
        consumer_key, consumer_secret, host,voucher_code,session_id
      )
  
 stk_response = hotspot_payment[:response]
 checkout_request_id = stk_response['CheckoutRequestID']
 merchant_request_id = stk_response['MerchantRequestID']

      if hotspot_payment[:success]
# voucher_record = HotspotVoucher.create!(
#   package: params[:package],
#   phone: phone_number,
#   voucher: voucher_code,
#   mac: params[:mac],
#   ip: params[:ip],
#   checkout_request_id: checkout_request_id,
#   merchant_request_id: merchant_request_id,

#   payment_status: 'pending'

# )

# create_voucher_radcheck(voucher_code, params[:package], 
# voucher_record.account_id)

# calculate_expiration(params[:package], voucher_record)

        render json: {
          message: 'Please check your phone to complete the payment',
          checkout_request_id: checkout_request_id
        }
      else
        render json: { error: 'Failed to initiate payment' }, status: :unprocessable_entity
      end
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
  if params[:phone].present?
   HotspotVoucher.find_by(voucher: params[:voucher]).update(phone: params[:phone])

expiration = HotspotVoucher.find_by(voucher: params[:voucher]).expiration
             if ActsAsTenant.current_tenant.sms_provider_setting.sms_provider == "SMS leopard"
               send_voucher(params[:phone], params[:voucher],
               expiration.strftime("%B %d, %Y at %I:%M %p"),
                params[:shared_users]
               )
               
             elsif ActsAsTenant.current_tenant.sms_provider_setting.sms_provider == "TextSms"
               send_voucher_text_sms(params[:phone], params[:voucher],
               expiration.strftime("%B %d, %Y at %I:%M %p"), 
               params[:shared_users]
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
#       voucher: generate_voucher_code
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

  tenant = ActsAsTenant.current_tenant
 active_sessions = RadAcct.where(
    account_id: tenant.id,
    acctstoptime: nil,
    framedprotocol: ''
  ).where('acctupdatetime > ?', 2.minutes.ago)
   maximum_active_sessions = active_sessions.count

# if tenant.hotspot_plan.present?

#   if !tenant.hotspot_plan.name == 'Hotspot Free Trial'
#     plan_limit = tenant.hotspot_plan.hotspot_subscribers.to_i
#     #  plan_limit = HotspotPlan.find_by(name: tenant.hotspot_plan.name).hotspot_subscribers.to_i
# Rails.logger.info "Hotspot Plan Maximum Subscribers =>#{tenant.hotspot_plan.hotspot_subscribers}"

    
#     if maximum_active_sessions >= plan_limit
#       render json: { 
#         error: "Maximum active sessions (#{plan_limit}) reached.Please upgrade your plan." 
#       }, status: :unprocessable_entity
#       return
#     end
#   end
#   end




  number_of_vouchers = params[:number_of_vouchers].to_i
  number_of_vouchers = 1 if number_of_vouchers < 1

  created_vouchers = []
  
  ActiveRecord::Base.transaction do
    number_of_vouchers.times do |index|
      voucher_code = generate_voucher_code
      
      @hotspot_voucher = HotspotVoucher.new(
        package: params[:package],
        shared_users: params[:shared_users],
        phone: params[:phone],
        voucher: voucher_code
      )

      calculate_expiration(params[:package], @hotspot_voucher,
       @hotspot_voucher.account_id)
      
      # Save within transaction - will rollback if any fail
      if @hotspot_voucher.save!
        # Create radcheck entry
        create_voucher_radcheck(voucher_code, params[:package], 
        @hotspot_voucher.account_id)
        
        # Add to created list
        created_vouchers << @hotspot_voucher
      end
    end
    
    # Create batch activity log
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
hotspot_package = "hotspot_#{account_id}_#{package.parameterize(separator: '_')}"

# rad_check = RadCheck.find_or_initialize_by(
#       username: pppoe_username,
#       radiusattribute: 'Cleartext-Password'
#     )
#     rad_check.update!(op: ':=', value: pppoe_password)

radcheck = RadCheck.find_or_initialize_by(username: hotspot_voucher,
account_id: account_id,
radiusattribute: 
'Cleartext-Password')  

radcheck.update!(op: ':=', value: hotspot_voucher)

# radcheck_simultanesous_use = RadCheck.find_or_initialize_by(username: hotspot_voucher, radiusattribute: 
# 'Simultaneous-Use')
# radcheck_simultanesous_use.update!(op: ':=',  value: shared_users)

rad_user_group = RadUserGroup.find_or_initialize_by(username: hotspot_voucher,
 groupname: hotspot_package, priority: 1, account_id: account_id)
rad_user_group.update!(username: hotspot_voucher, groupname: hotspot_package, priority: 1)

rad_reply = RadReply.find_or_initialize_by(username: hotspot_voucher, 
radiusattribute: 'Idle-Timeout',
account_id: account_id,
 op: ':=', value: '5000')
 
rad_reply.update!(username: hotspot_voucher, 
radiusattribute: 'Idle-Timeout', op: ':=', value: '5000')

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
  return render json: { error: 'ip is required' }, status: :bad_request unless params[:ip].present?

  host = request.headers['X-Subdomain']
  account = Account.find_by(subdomain: host)
  return render json: { error: 'Account not found' }, status: :not_found unless account

  # 🔹 Find voucher
  @hotspot_voucher = HotspotVoucher.find_by(voucher: params[:voucher])
  return render json: { error: 'Invalid voucher or username' }, status: :not_found unless @hotspot_voucher

  # 🔹 Expiration check
  if @hotspot_voucher.expiration.present? && @hotspot_voucher.expiration < Time.current
    return render json: { error: 'Voucher Or Username expired' }, status: :forbidden
  end


  active_sessions = get_active_sessions(params[:voucher])
  package = HotspotPackage.find_by(name: @hotspot_voucher.package)
  shared_users = package&.shared_users.to_i

  if active_sessions.any?
    active_voucher_sessions = active_sessions.select { |s| s.include?(params[:voucher]) }
    if active_voucher_sessions.count >= shared_users
      return render json: {
        error: "Voucher already used. Max devices allowed: #{shared_users}"
      }, status: :forbidden
    end
  end

  nas_routers = NasRouter.where(account_id: account.id)

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
        }
      )

      if response.code == 200
        @hotspot_voucher.update!(status: 'used', last_logged_in: Time.now, 
        ip: params[:ip], mac: params[:mac], used_voucher: true)

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

    rescue StandardError => e
      Rails.logger.info "REST login error: #{e.message}"
      next
    end
  end

  render json: { error: 'Failed to connect on all routers' }, status: :unprocessable_entity
end

  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_voucher
      @hotspot_voucher = HotspotVoucher.find_by(id: params[:id])
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
    status = expiration_time > Time.current ? "active" : "expired"
    voucher_created.update(status: status,  expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),)
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
  # voucher_type = HotspotSetting.first&.voucher_type || 'Mixed'
voucher_type = ActsAsTenant.current_tenant&.hotspot_setting&.voucher_type || 'Mixed'

  loop do
    code =
      case voucher_type
      when 'Numeric'
        # Example: 8-digit numeric code
        rand(10**7..10**8 - 1).to_s

      when 'Fixed'
        # Example: FIXED-XXXX (you can customize)
        "FIXED-#{SecureRandom.hex(2).upcase}"

      when 'Words'
        # Example: WORD-WORD (easy to read)
        words = %w[
          SKY NET FAST WIFI DATA ZONE LINK CLOUD
          SPEED HOT SPOT CONNECT
        ]
        "#{words.sample}-#{words.sample}"

      when 'Mixed'
        # Example: A9F3C8D2
        SecureRandom.hex(4).upcase

      else
        # Fallback
        SecureRandom.hex(4).upcase
      end

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


      def send_voucher(phone_number, voucher_code,
        voucher_expiration, shared_users
        )
      # api_key = ActsAsTenant.current_tenant.sms_setting.api_key
      # api_secret = ActsAsTenant.current_tenant.sms_setting.api_secret
    HotspotVoucher.find_by(voucher: voucher_code).update(sms_sent: true)
      api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
    api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
    
              api_key = api_key
              api_secret = api_secret
             
      sms_template =  ActsAsTenant.current_tenant.sms_template
      send_voucher_template = sms_template&.send_voucher_template
    #   original_message = sms_template ?  MessageTemplate.interpolate(send_voucher_template,{
        
    #   voucher_code: voucher_code,
    #   voucher_expiration: voucher_expiration

    #   })  :   "Your voucher code: #{voucher_code} for #{shared_users} devices. This code is valid until #{voucher_expiration}.
    #  Enjoy your browsing"
               original_message = "Your voucher code is: #{voucher_code}. This code is valid until #{voucher_expiration}.
  #    Enjoy your browsing"
      
      
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
                  # render json: { error: "Failed to send message: #{sms_data['message']}" }
                  Rails.logger.info "Failed to send message: #{sms_data['message']}"
                end
              else
                puts "Failed to send message: #{response.body}"
                # render json: { error: "Failed to send message: #{response.body}" }
              end
            end





           def send_voucher_text_sms(phone_number, voucher_code, voucher_expiration,
             shared_users
            )
       HotspotVoucher.find_by(voucher: voucher_code).update(sms_sent: true)

  sms_setting = SmsSetting.find_by(sms_provider: 'TextSms')

  # if sms_setting.nil?
  #   render json: { error: "SMS provider not found" }, status: :not_found
  #   return
  # end

  api_key = sms_setting&.api_key
  partnerID = sms_setting&.partnerID 

  sms_template = ActsAsTenant.current_tenant.sms_template
  send_voucher_template = sms_template&.send_voucher_template

  # original_message = if sms_template
  #   MessageTemplate.interpolate(send_voucher_template, { voucher_code: voucher_code })
  # else
  #   "Your voucher code: #{voucher_code} for #{shared_users} devices. This code is valid until #{voucher_expiration}.
  #    Enjoy your browsing"
  # end

  original_message = "Your voucher code is: #{voucher_code}. This code is valid until #{voucher_expiration}.
  #    Enjoy your browsing"
  #    
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












