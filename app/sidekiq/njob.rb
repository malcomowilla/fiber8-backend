# class PayIspsJob
#   include Sidekiq::Job
#   queue_as :default

#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
#         process_tenant_payout(tenant)
#       end
#     end
#   end

#   private

#   def process_tenant_payout(tenant)
#     mpesa_setting = tenant.hotspot_mpesa_setting
#     return unless mpesa_setting.present?

#     phone_number = mpesa_setting.phone_number
#     return if phone_number.blank?

#     # ✅ Get unpaid revenues older than 4 minutes
#     revenues = HotspotMpesaRevenue
#       .where(account_id: tenant.id, paid_out: false)
#       .where("created_at <= ?", 4.minutes.ago)

#     return if revenues.empty?

#     total_amount = revenues.sum(:amount)
#     return if total_amount <= 0 || total_amount < 10

#     # ✅ Fees
#     transaction_cost = total_amount * 0.01

#     plan = tenant.hotspot_and_dial_plan
#     is_trial = plan&.name == "Free Trial"

#     platform_fee = is_trial ? 0 : total_amount * 0.04

#     net_amount = total_amount - transaction_cost - platform_fee
#     return if net_amount <= 0

#     Rails.logger.info "Tenant #{tenant.id} total: #{total_amount}, net: #{net_amount}"

#     # ✅ Mark as paid BEFORE sending (prevents double payout)
#     batch_id = SecureRandom.uuid

#     revenues.update_all(
#       paid_out: true,
#       paid_out_at: Time.current,
#       payout_batch_id: batch_id
#     )

#     # ✅ Send money
#     send_b2c(phone_number, net_amount.to_i, tenant)
#   end

#   # --------------------------
#   # 🔁 B2C PAYMENT
#   # --------------------------
#   def send_b2c(phone_number, amount, tenant)
#     token = fetch_access_token
#     return unless token

#     payload = {
#       OriginatorConversationID: SecureRandom.hex(10),
#       InitiatorName: ENV['API_INITIATOR_USERNAME'],
#       SecurityCredential: ENV['B2C_API_INITIATOR_PASSWORD'],
#       CommandID: "BusinessPayment",
#       Amount: amount,
#       PartyA: ENV['B2C_SHORTCODE'],
#       PartyB: format_phone(phone_number),
#       Remarks: "ISP payout",
#       QueueTimeOutURL: "#{callback_base_url(tenant)}/b2c_timeout",
#       ResultURL: "#{callback_base_url(tenant)}/b2c_result",
#       Occassion: "ISPSettlement"
#     }

#     begin
#       response = RestClient.post(
#         "https://api.safaricom.co.ke/mpesa/b2c/v1/paymentrequest",
#         payload.to_json,
#         { content_type: :json, Authorization: "Bearer #{token}" }
#       )

#       Rails.logger.info "B2C success: #{response.body}"

#     rescue RestClient::ExceptionWithResponse => e
#       Rails.logger.error "B2C error: #{e.response.body}"
#     end
#   end

#   # --------------------------
#   # 🔐 ACCESS TOKEN
#   # --------------------------
#   def fetch_access_token
#     consumer_key = ENV['CONSUMER_KEY']
#     consumer_secret = ENV['CONSUMER_SECRET']

#     response = RestClient.get(
#       "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
#       Authorization: "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}"
#     )

#     JSON.parse(response.body)["access_token"]

#   rescue RestClient::ExceptionWithResponse => e
#     Rails.logger.error "Token error: #{e.response}"
#     nil
#   end

#   # --------------------------
#   # 📞 FORMAT PHONE
#   # --------------------------
#   def format_phone(phone)
#     phone.gsub(/^0/, '254')
#   end

#   # --------------------------
#   # 🌐 CALLBACK URL
#   # --------------------------
#   def callback_base_url(tenant)
#     "https://#{tenant.subdomain}.#{ENV['HOST']}"
#   end
# end =>class GenerateInvoiceJob
#   include Sidekiq::Job
#   queue_as :invoices
#   sidekiq_options lock: :until_executed, lock_timeout: 0

#   PPPoE_PRICE_PER_CLIENT = 25
#   HOTSPOT_PERCENTAGE = 0.04

#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
#         Rails.logger.info "Processing invoice for => #{tenant.subdomain}"
#         Rails.logger.info "Processing invoice for id => #{tenant.id}"

#         # hotspot_billable = hotspot_plan_billable?(tenant)
#         # pppoe_billable   = pppoe_plan_billable?(tenant)
#         hotspot_and_dial_plan_billable = hotspot_and_dial_plan_billable?(tenant)
#         next unless hotspot_and_dial_plan_billable

#         # last_invoice = tenant.invoices.order(created_at: :desc).first
#         last_invoice = tenant.invoices.where(status: 'unpaid').order(created_at: :desc).first

#         if last_invoice&.last_invoiced_at.present? &&
#            last_invoice.last_invoiced_at > 30.days.ago
#           Rails.logger.info "Skipping invoice for #{tenant.subdomain} — recently invoiced"
#           next
#         end

#         generate_usage_invoice(tenant, hotspot_billable, pppoe_billable)
#       end
#     end
#   end

#   private

#   # -----------------------
#   # BILLABLE CONDITIONS
#   # -----------------------

#   def hotspot_and_dial_plan_billable?(tenant)
#     tenant.hotspot_and_dial_plan.present? &&
#       tenant.hotspot_and_dial_plan.name.present? &&
#       # tenant.hotspot_plan.name != "Hotspot Free Trial" &&
#       tenant.hotspot_and_dial_plan.expiry.present? &&
#       tenant.hotspot_and_dial_plan.expiry - 1.day < Time.current
#   end

  


#   def generate_usage_invoice(tenant, hotspot_and_dial_plan_billable
#      )
#     Rails.logger.info "Generating invoice for #{tenant.subdomain}"

#     hotspot_total = 0
#     hotspot_charge = 0
#     pppoe_clients = 0
#     pppoe_charge = 0

#     # if hotspot_billable
#     #   hotspot_total, hotspot_charge = calculate_hotspot_charge(tenant)
#     # end

#     # if pppoe_billable
#     #   pppoe_clients, pppoe_charge = calculate_pppoe_charge(tenant)
#     # end
#     if hotspot_and_dial_plan_billable
#       hotspot_total, hotspot_charge = calculate_hotspot_charge(tenant)
#       pppoe_clients, pppoe_charge = calculate_pppoe_charge(tenant)
#     end

#     total_amount = hotspot_charge + pppoe_charge
#     return if total_amount.zero?


#         # Create structured description as JSON
#     invoice_description_json = {
#       summary: "Billing Summary",
#       items: []
#     }

#     # Add hotspot item if applicable
#     if hotspot_charge > 0
#       invoice_description_json[:items] << {
#         description: "Hotspot Revenue Share",
#         details: "4% of total hotspot revenue",
#         quantity: hotspot_total,
#         unit: "KES",
#         rate: "4%",
#         amount: hotspot_charge,
#         currency: "KES"
#       }
#     end

#     # Add PPPoE item if applicable
#     if pppoe_charge > 0
#       invoice_description_json[:items] << {
#         description: "PPPoE Client Management",
#         details: "Per client monthly charge",
#         quantity: "#{pppoe_clients} clients",
#         unit: "clients",
#         rate: "25 KES/client",
#         amount: pppoe_charge,
#         currency: "KES"
#       }
#     end


#     invoice = Invoice.create!(
#       invoice_number: generate_invoice_number,
#       plan_name: "Usage Billing",
#       invoice_date: Time.current,
#       due_date: Time.current + 2.days,
#       # invoice_desciption: invoice_description(
#       #   hotspot_total,
#       #   hotspot_charge,
#       #   pppoe_clients,
#       #   pppoe_charge
#       # ),
#       invoice_desciption: invoice_description_json.to_json,
#       total: total_amount,
#       status: "unpaid",
#       account_id: tenant.id,
#       last_invoiced_at: Time.current
#     )

#     send_invoice_sms(tenant.users.where(role: "super_administrator").first.phone_number, 
#  invoice.due_date, invoice.invoice_number,
#   tenant.users.where(role: "super_administrator").first.username, 
#   invoice.plan_name)
#   end





#   def send_invoice_sms(phone_number, due_date, 
#     invoice_number, username, plan_name)
#     provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider
    

#     case provider
#     when 'TextSms'
#       send_expiration_text_sms(phone_number, due_date, invoice_number, 
#       username, plan_name)
#     when 'SMS leopard'
#       send_expiration(phone_number, due_date, invoice_number, username, plan_name)
#     else
#       Rails.logger.info "No valid SMS provider configured"
#     end
#   end









#   def send_expiration(phone_number, due_date, invoice_number, username, plan_name)

#     # provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider

#     api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
#     api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
    

#     sms_template = ActsAsTenant.current_tenant.sms_template
#     # send_voucher_template = sms_template&.send_voucher_template
#     original_message =  "Hello, #{username} your invoice #{invoice_number}  for #{plan_name} has been generated and is due on #{due_date.strftime("%B %d, %Y at %I:%M %p")}. Please renew your subscription to admin your network."

#     sender_id = "SMS_TEST"
#     uri = URI("https://api.smsleopard.com/v1/sms/send")
#     params = {
#       username: api_key,
#       password: api_secret,
#       message: original_message,
#       destination: phone_number,
#       source: sender_id
#     }
#     uri.query = URI.encode_www_form(params)

#     response = Net::HTTP.get_response(uri)
#     handle_sms_response(response, original_message, phone_number)
#   end



  
#   def send_expiration_text_sms(phone_number, due_date, invoice_number, username, plan_name)
#     api_key = SmsSetting.find_by(sms_provider: 'TextSms')&.api_key
#     partnerID = SmsSetting.find_by(sms_provider: 'TextSms')&.partnerID
#     shortcode = SmsSetting.find_by(sms_provider: 'TextSms')&.sender_id

#     sms_template = ActsAsTenant.current_tenant.sms_template
#     # send_voucher_template = sms_template&.send_voucher_template
#         original_message =  "Hello, #{username} your invoice #{invoice_number}  for #{plan_name} has been generated and is due on #{due_date.strftime("%B %d, %Y at %I:%M %p")}. Please renew your subscription to admin your network."


#     uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
#     params = {
#       apikey: api_key,
#       message: original_message,
#       mobile: phone_number,
#       partnerID: partnerID,
#       shortcode: shortcode,

#     }
#     uri.query = URI.encode_www_form(params)

#     response = Net::HTTP.get_response(uri)
#     handle_sms_response(response, original_message, phone_number)
#   end






#    def handle_sms_response(response, message, phone_number)
#     if response.is_a?(Net::HTTPSuccess)
#       sms_data = JSON.parse(response.body)
#       if sms_data['responses'] && sms_data['responses'][0]['respose-code'] == 200
#         sms_recipient = sms_data['responses'][0]['mobile']
#         sms_status = sms_data['responses'][0]['response-description']
        
#         Rails.logger.info "Recipient: #{sms_recipient}, Status: #{sms_status}"

#         SystemAdminSm.create!(
#           user: sms_recipient,
#           message: message,
#           status: sms_status,
#           date: Time.current,
#           system_user: 'system',
#           sms_provider: 'SMS leopard'
#         )
#       else
#         Rails.logger.info "Failed to send message: #{sms_data['responses'][0]['response-description']}"
#       end
#     else
#       Rails.logger.info "Failed to send message: #{response.body}"
#     end
#   end


  

#   def calculate_hotspot_charge(tenant)
#     hotspot_total = HotspotMpesaRevenue
#                       .where(account_id: tenant.id)
#                       .where(created_at: Time.current.beginning_of_month..Time.current)
#                       .sum(:amount)

#     # hotspot_charge = hotspot_total * HOTSPOT_PERCENTAGE
#      hotspot_charge = (hotspot_total * HOTSPOT_PERCENTAGE).round
#     [hotspot_total, hotspot_charge]
#   end

#   def calculate_pppoe_charge(tenant)
#     pppoe_clients = Subscriber.where(account_id: tenant.id).count
#     pppoe_charge = pppoe_clients * PPPoE_PRICE_PER_CLIENT
#     [pppoe_clients, pppoe_charge]
#   end


#   # -----------------------



#   # HELPERS
#   # -----------------------

#   def invoice_description(hotspot_total, hotspot_charge, pppoe_clients,
#      pppoe_charge)
#     <<~DESC
#     Billing Summary:
#     Hotspot revenue: #{hotspot_total} KES
#     Hotspot charge (4%): #{hotspot_charge} KES
#     PPPoE clients: #{pppoe_clients}
#     PPPoE charge (25 KES per client): #{pppoe_charge} KES
#     DESC
#   end


# #   def invoice_description(hotspot_total, hotspot_charge, pppoe_clients, pppoe_charge)
# #   [
# #     "Billing Summary",
# #     "Hotspot revenue: #{hotspot_total} KSH",
# #     "Hotspot charge (4% of total revenue): #{hotspot_charge} KSH",
# #     "PPPoE clients: #{pppoe_clients}",
# #     "PPPoE charge (25 KSH per client): #{pppoe_charge} KSH"
# #   ].join("\n")
# # end


#   def generate_invoice_number
#     "INV#{rand(100..999)}"
#   end



# end => i want pay isp job to borow some concept from Generate invoice job(the 4% platfform fee wil be charged)









































































































# class GenerateInvoiceJob
#   include Sidekiq::Job
#   queue_as :invoices
#   sidekiq_options lock: :until_executed, lock_timeout: 0

#   PPPoE_PRICE_PER_CLIENT = 25
#   HOTSPOT_PERCENTAGE = 0.04
#   SUBSCRIPTION_FEE = 500

#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
#         Rails.logger.info "Processing invoice for => #{tenant.subdomain}"
#         Rails.logger.info "Processing invoice for id => #{tenant.id}"

#         # hotspot_billable = hotspot_plan_billable?(tenant)
#         # pppoe_billable   = pppoe_plan_billable?(tenant)
#         hotspot_and_dial_plan_billable = hotspot_and_dial_plan_billable?(tenant)
#         next unless hotspot_and_dial_plan_billable

#         # last_invoice = tenant.invoices.order(created_at: :desc).first
#         last_invoice = tenant.invoices.where(status: 'unpaid').order(created_at: :desc).first

#         if last_invoice&.last_invoiced_at.present? &&
#            last_invoice.last_invoiced_at > 25.days.ago
#           Rails.logger.info "Skipping invoice for #{tenant.subdomain} — recently invoiced"
#           next
#         end

#         generate_usage_invoice(tenant, hotspot_billable, pppoe_billable)
#       end
#     end
#   end

#   private

#   # -----------------------
#   # BILLABLE CONDITIONS
#   # -----------------------

#   def hotspot_and_dial_plan_billable?(tenant)
#     tenant.hotspot_and_dial_plan.present? &&
#       tenant.hotspot_and_dial_plan.name.present? &&
#       # tenant.hotspot_plan.name != "Hotspot Free Trial" &&
#       tenant.hotspot_and_dial_plan.expiry.present? &&
#       return unless tenant.hotspot_and_dial_plan.expiry - 5.days <= Time.current

#   end

  


#   def generate_usage_invoice(tenant, hotspot_and_dial_plan_billable
#      )
#     Rails.logger.info "Generating invoice for #{tenant.subdomain}"

#     hotspot_total = 0
#     hotspot_charge = 0
#     pppoe_clients = 0
#     pppoe_charge = 0

#     # if hotspot_billable
#     #   hotspot_total, hotspot_charge = calculate_hotspot_charge(tenant)
#     # end

#     # if pppoe_billable
#     #   pppoe_clients, pppoe_charge = calculate_pppoe_charge(tenant)
#     # end
#     if hotspot_and_dial_plan_billable
#       hotspot_total, hotspot_charge = calculate_hotspot_charge(tenant)
#       pppoe_clients, pppoe_charge = calculate_pppoe_charge(tenant)
#     end

#     total_amount = hotspot_charge + pppoe_charge
#     # return if total_amount.zero?
    
#     total_amount = SUBSCRIPTION_FEE if total_amount.zero?

#         # Create structured description as JSON
#     invoice_description_json = {
#       summary: "Billing Summary",
#       items: []
#     }

#     # Add hotspot item if applicable
#     if hotspot_charge > 0
#       invoice_description_json[:items] << {
#         description: "Hotspot Revenue Share",
#         details: "4% of total hotspot revenue",
#         quantity: hotspot_total,
#         unit: "KES",
#         rate: "4%",
#         amount: hotspot_charge,
#         currency: "KES"
#       }
#     end

#     # Add PPPoE item if applicable
#     if pppoe_charge > 0
#       invoice_description_json[:items] << {
#         description: "PPPoE Client Management",
#         details: "Per client monthly charge",
#         quantity: "#{pppoe_clients} clients",
#         unit: "clients",
#         rate: "25 KES/client",
#         amount: pppoe_charge,
#         currency: "KES"
#       }
#     end


#     invoice = Invoice.create!(
#       invoice_number: generate_invoice_number,
#       plan_name: "Usage Billing",
#       invoice_date: Time.current,
#       due_date: Time.current + 5.days,
#       # invoice_desciption: invoice_description(
#       #   hotspot_total,
#       #   hotspot_charge,
#       #   pppoe_clients,
#       #   pppoe_charge
#       # ),
#       invoice_desciption: invoice_description_json.to_json,
#       total: total_amount,
#       status: "unpaid",
#       account_id: tenant.id,
#       last_invoiced_at: Time.current
#     )

#     send_invoice_sms(tenant.users.where(role: "super_administrator").first.phone_number, 
#  invoice.due_date, invoice.invoice_number,
#   tenant.users.where(role: "super_administrator").first.username, 
#   invoice.plan_name)
#   end





#   def send_invoice_sms(phone_number, due_date, 
#     invoice_number, username, plan_name)
#     provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider
    

#     case provider
#     when 'TextSms'
#       send_expiration_text_sms(phone_number, due_date, invoice_number, 
#       username, plan_name)
#     when 'SMS leopard'
#       send_expiration(phone_number, due_date, invoice_number, username, plan_name)
#     else
#       Rails.logger.info "No valid SMS provider configured"
#     end
#   end









#   def send_expiration(phone_number, due_date, invoice_number, 
    
#   endusername, plan_name)

#     # provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider

#     api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
#     api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
    

#     sms_template = ActsAsTenant.current_tenant.sms_template
#     # send_voucher_template = sms_template&.send_voucher_template
#     original_message =  "Hello, #{username} your invoice #{invoice_number}  for #{plan_name} has been generated and is due on #{due_date.strftime("%B %d, %Y at %I:%M %p")}. Please renew your subscription to admin your network."

#     sender_id = "SMS_TEST"
#     uri = URI("https://api.smsleopard.com/v1/sms/send")
#     params = {
#       username: api_key,
#       password: api_secret,
#       message: original_message,
#       destination: phone_number,
#       source: sender_id
#     }
#     uri.query = URI.encode_www_form(params)

#     response = Net::HTTP.get_response(uri)
#     handle_sms_response(response, original_message, phone_number)
#   end



  
#   def send_expiration_text_sms(phone_number, due_date, invoice_number, username, plan_name)
#     api_key = SmsSetting.find_by(sms_provider: 'TextSms')&.api_key
#     partnerID = SmsSetting.find_by(sms_provider: 'TextSms')&.partnerID
#     shortcode = SmsSetting.find_by(sms_provider: 'TextSms')&.sender_id

#     sms_template = ActsAsTenant.current_tenant.sms_template
#     # send_voucher_template = sms_template&.send_voucher_template
#         original_message =  "Hello, #{username} your invoice #{invoice_number}  for #{plan_name} has been generated and is due on #{due_date.strftime("%B %d, %Y at %I:%M %p")}. Please renew your subscription to admin your network."


#     uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
#     params = {
#       apikey: api_key,
#       message: original_message,
#       mobile: phone_number,
#       partnerID: partnerID,
#       shortcode: shortcode,

#     }
#     uri.query = URI.encode_www_form(params)

#     response = Net::HTTP.get_response(uri)
#     handle_sms_response(response, original_message, phone_number)
#   end






#    def handle_sms_response(response, message, phone_number)
#     if response.is_a?(Net::HTTPSuccess)
#       sms_data = JSON.parse(response.body)
#       if sms_data['responses'] && sms_data['responses'][0]['respose-code'] == 200
#         sms_recipient = sms_data['responses'][0]['mobile']
#         sms_status = sms_data['responses'][0]['response-description']
        
#         Rails.logger.info "Recipient: #{sms_recipient}, Status: #{sms_status}"

#         SystemAdminSm.create!(
#           user: sms_recipient,
#           message: message,
#           status: sms_status,
#           date: Time.current,
#           system_user: 'system',
#           sms_provider: 'SMS leopard'
#         )
#       else
#         Rails.logger.info "Failed to send message: #{sms_data['responses'][0]['response-description']}"
#       end
#     else
#       Rails.logger.info "Failed to send message: #{response.body}"
#     end
#   end


  

#   def calculate_hotspot_charge(tenant)
#     hotspot_total = HotspotMpesaRevenue
#                       .where(account_id: tenant.id)
#                       .where(created_at: Time.current.beginning_of_month..Time.current)
#                       .sum(:amount)

#     # hotspot_charge = hotspot_total * HOTSPOT_PERCENTAGE
#      hotspot_charge = (hotspot_total * HOTSPOT_PERCENTAGE).round
#     [hotspot_total, hotspot_charge]
#   end



#   def calculate_pppoe_charge(tenant)
#     pppoe_clients = Subscriber.where(account_id: tenant.id, status: 'active').count
#     pppoe_charge = pppoe_clients * PPPoE_PRICE_PER_CLIENT
#     [pppoe_clients, pppoe_charge]
#   end


#   # -----------------------



#   # HELPERS
#   # -----------------------

#   def invoice_description(hotspot_total, hotspot_charge, pppoe_clients,
#      pppoe_charge)
#     <<~DESC
#     Billing Summary:
#     Hotspot revenue: #{hotspot_total} KES
#     Hotspot charge (4%): #{hotspot_charge} KES
#     PPPoE clients: #{pppoe_clients}
#     PPPoE charge (25 KES per client): #{pppoe_charge} KES
#     DESC
#   end


# #   def invoice_description(hotspot_total, hotspot_charge, pppoe_clients, pppoe_charge)
# #   [
# #     "Billing Summary",
# #     "Hotspot revenue: #{hotspot_total} KSH",
# #     "Hotspot charge (4% of total revenue): #{hotspot_charge} KSH",
# #     "PPPoE clients: #{pppoe_clients}",
# #     "PPPoE charge (25 KSH per client): #{pppoe_charge} KSH"
# #   ].join("\n")
# # end


#   def generate_invoice_number
#     "INV#{rand(100..999)}"
#   end



# end



















# class PayIspsJob
#   include Sidekiq::Job
#   queue_as :default

#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
#         tenant.hotspot_mpesa_setting.no_api_keys == true ? process_tenant_payout(tenant) : nil 
#         process_tenant_payout(tenant)
#       end
#     end
#   end

#   private

#   def process_tenant_payout(tenant)
#     mpesa_setting = tenant.hotspot_mpesa_setting
#     return unless mpesa_setting.present?

#     phone_number = mpesa_setting.phone_number
#     return if phone_number.blank?

#     # ✅ Get unpaid revenues older than 4 minutes
#     revenues = HotspotMpesaRevenue
#       .where(account_id: tenant.id, paid_out: false)
#       .where("created_at <= ?", 4.minutes.ago)

#     return if revenues.empty?

#     total_amount = revenues.sum(:amount)
#     return if total_amount <= 0 || total_amount < 10

#     # ✅ Fees
#     # transaction_cost = total_amount * 0.01
#     transaction_cost = (total_amount * 0.01).round

#     plan = tenant.hotspot_and_dial_plan
#     is_trial = plan&.name == "Free Trial"

#     platform_fee = is_trial ? 0 : total_amount * 0.04

#     net_amount = total_amount - transaction_cost - platform_fee
#     # net_amount = total_amount - transaction_cost
#     return if net_amount <= 0

#     Rails.logger.info "Tenant #{tenant.id} total: #{total_amount}, net: #{net_amount}"

#     # ✅ Mark as paid BEFORE sending (prevents double payout)
#     # batch_id = SecureRandom.uuid

#     revenues.update_all(
#       paid_out: true,
#       paid_out_at: Time.current,
#       # payout_batch_id: batch_id
#     )

#     # ✅ Send money
#     send_b2c(phone_number, net_amount.to_i, tenant)
#   end

#   # --------------------------
#   # 🔁 B2C PAYMENT
#   # --------------------------
#   def send_b2c(phone_number, amount, tenant)
#     token = fetch_access_token
#     return unless token

#     payload = {
#       OriginatorConversationID: SecureRandom.hex(10),
#       InitiatorName: ENV['API_INITIATOR_USERNAME'],
#       SecurityCredential: ENV['B2C_API_INITIATOR_PASSWORD'],
#       CommandID: "BusinessPayment",
#       Amount: amount,
#       PartyA: ENV['B2C_SHORTCODE'],
#       PartyB: format_phone(phone_number),
#       Remarks: "ISP payout",
#       QueueTimeOutURL: "#{callback_base_url(tenant)}/b2c_timeout",
#       ResultURL: "#{callback_base_url(tenant)}/b2c_result",
#       Occassion: "ISPSettlement"
#     }

#     begin
#       response = RestClient.post(
#         "https://api.safaricom.co.ke/mpesa/b2c/v1/paymentrequest",
#         payload.to_json,
#         { content_type: :json, Authorization: "Bearer #{token}" }
#       )

#       Rails.logger.info "B2C success: #{response.body}"

#     rescue RestClient::ExceptionWithResponse => e
#       Rails.logger.error "B2C error: #{e.response.body}"
#     end
#   end

#   # --------------------------
#   # 🔐 ACCESS TOKEN
#   # --------------------------
#   def fetch_access_token
#     consumer_key = ENV['CONSUMER_KEY']
#     consumer_secret = ENV['CONSUMER_SECRET']

#     response = RestClient.get(
#       "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
#       Authorization: "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}"
#     )

#     JSON.parse(response.body)["access_token"]

#   rescue RestClient::ExceptionWithResponse => e
#     Rails.logger.error "Token error: #{e.response}"
#     nil
#   end

#   # --------------------------
#   # 📞 FORMAT PHONE
#   # --------------------------
#   def format_phone(phone)
#     phone.gsub(/^0/, '254')
#   end

#   # --------------------------
#   # 🌐 CALLBACK URL
#   # --------------------------
#   def callback_base_url(tenant)
#     "https://#{tenant.subdomain}.#{ENV['HOST']}"
#   end
# end







class Njob
  include Sidekiq::Job
end
