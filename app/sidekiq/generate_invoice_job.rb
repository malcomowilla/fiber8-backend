
# class GenerateInvoiceJob
#   include Sidekiq::Job
#   queue_as :invoices

#   SUBSCRIPTION_FEE = 500

#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
#         # return unless tenant.hotspot_mpesa_setting.no_api_keys.nil?
#         # tenant.hotspot_mpesa_setting.no_api_keys == false ? process_subscription_invoice(tenant) : nil
#         setting = tenant.hotspot_mpesa_setting
#     next if setting.nil?                     # skip tenants with no settings
#     next if setting.no_api_keys == true      # skip if they use the "no API keys" mode
#     # only reach here if setting exists and no_api_keys is false (i.e., they have API keys)
#     process_subscription_invoice(tenant)
    
#         # process_subscription_invoice(tenant)
#       end
#     end
#   end

#   private






#   def process_subscription_invoice(tenant)
#     plan = tenant.hotspot_and_dial_plan
#     return unless plan.present?
#     return unless plan.expiry.present?
#     # return unless plan.name == "Free Trial"
#     # ✅ Trigger 5 days before expiry
#     return unless plan.expiry - 5.days <= Time.current

#     # last_invoice = tenant.invoices.where(plan_name: "Subscription Fee").order(created_at: :desc).first
#     last_invoice = tenant.invoices.where(status: 'unpaid').order(created_at: :desc).first

#     # ✅ Prevent duplicate invoices
#     if last_invoice&.last_invoiced_at.present? &&
#        last_invoice.last_invoiced_at > 25.days.ago
#       Rails.logger.info "Skipping invoice for #{tenant.subdomain}"
#       return
#     end

#     create_subscription_invoice(tenant, plan)
#   end

#   def create_subscription_invoice(tenant, plan)
#     invoice = Invoice.create!(
#       invoice_number: generate_invoice_number,
#       plan_name: "Subscription Fee",
#       invoice_date: Time.current,
#       due_date: plan.expiry,
#       invoice_desciption: {
#         summary: "Monthly Subscription",
#         items: [
#           {
#             description: "System Access Fee",
#             details: "Monthly ISP billing platform access",
#             amount: SUBSCRIPTION_FEE,
#             currency: "KES"
#           }
#         ]
#       }.to_json,
#       total: SUBSCRIPTION_FEE,
#       status: "unpaid",
#       account_id: tenant.id,
#       last_invoiced_at: Time.current
#     )

#     send_invoice_sms(
#       tenant.users.where(role: "super_administrator").first.phone_number,
#       invoice.due_date,
#       invoice.invoice_number,
#       tenant.users.where(role: "super_administrator").first.username,
#       invoice.plan_name
#     )
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





# def send_expiration(phone_number, due_date, invoice_number, 
    
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



  
#   def send_expiration_text_sms(phone_number, due_date, invoice_number, 
#     username, plan_name)
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







#   def generate_invoice_number
#     "INV#{SecureRandom.hex(3).upcase}"
#   end
# end
# 








class GenerateInvoiceJob
  include Sidekiq::Job
  queue_as :invoices
  sidekiq_options lock: :until_executed, lock_timeout: 0

  PPPoE_PRICE_PER_CLIENT = 25
  HOTSPOT_PERCENTAGE = 0.04
  SUBSCRIPTION_FEE = 500

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        Rails.logger.info "Processing invoice for tenant: #{tenant.subdomain} (id: #{tenant.id})"

        # Check if billing is required (5 days before plan expiry)
        billable = hotspot_and_dial_plan_billable?(tenant)
        next unless billable

        # Avoid duplicate invoices (only one unpaid invoice every 25 days)
        last_unpaid = tenant.invoices.where(status: 'unpaid').order(created_at: :desc).first
        if last_unpaid&.last_invoiced_at.present? && last_unpaid.last_invoiced_at > 25.days.ago
          Rails.logger.info "Skipping invoice for #{tenant.subdomain} — recent unpaid invoice exists"
          next
        end

        generate_usage_invoice(tenant)
      end
    end
  end

  private

  # Returns true if the tenant has a valid hotspot/dial plan and its expiry is within 5 days
  def hotspot_and_dial_plan_billable?(tenant)
    plan = tenant.hotspot_and_dial_plan
    return false unless plan.present?
    return false unless plan.expiry.present?

    # Trigger invoice 5 days before expiry
    plan.expiry - 5.days <= Time.current
  end

  def generate_usage_invoice(tenant)
    Rails.logger.info "Generating usage invoice for #{tenant.subdomain}"

    # Calculate hotspot charge (4% of revenue)
    hotspot_total, hotspot_charge = calculate_hotspot_charge(tenant)

    # Calculate PPPoE charge (KES 25 per active client)
    pppoe_clients, pppoe_charge = calculate_pppoe_charge(tenant)

    total_amount = hotspot_charge + pppoe_charge
    total_amount = SUBSCRIPTION_FEE if total_amount.zero?

    # Build JSON description
    description_items = []
    if hotspot_charge > 0
      description_items << {
        description: "Hotspot Revenue Share",
        details: "4% of total hotspot revenue",
        quantity: hotspot_total,
        unit: "KES",
        rate: "4%",
        amount: hotspot_charge,
        currency: "KES"
      }
    end
    if pppoe_charge > 0
      description_items << {
        description: "PPPoE Client Management",
        details: "Per client monthly charge",
        quantity: "#{pppoe_clients} clients",
        unit: "clients",
        rate: "25 KES/client",
        amount: pppoe_charge,
        currency: "KES"
      }
    end

    invoice = Invoice.create!(
      invoice_number: generate_invoice_number,
      plan_name: "Usage Billing",
      invoice_date: Time.current,
      due_date: Time.current + 5.days,
      invoice_desciption: { summary: "Billing Summary", items: description_items }.to_json,
      total: total_amount,
      status: "unpaid",
      account_id: tenant.id,
      last_invoiced_at: Time.current
    )

    # Send SMS notification to super admin
    admin = tenant.users.where(role: "super_administrator").first
    if admin&.phone_number.present?
      send_invoice_sms(admin.phone_number, invoice.due_date, invoice.invoice_number, admin.username, invoice.plan_name, tenant)
    end
  end

  def calculate_hotspot_charge(tenant)
    hotspot_total = HotspotMpesaRevenue
                      .where(account_id: tenant.id)
                      .where(created_at: Time.current.beginning_of_month..Time.current)
                      .sum(:amount)
    hotspot_charge = (hotspot_total * HOTSPOT_PERCENTAGE).round
    [hotspot_total, hotspot_charge]
  end

  def calculate_pppoe_charge(tenant)
    pppoe_clients = Subscriber.where(status: 'active').count
    pppoe_charge = pppoe_clients * PPPoE_PRICE_PER_CLIENT
    [pppoe_clients, pppoe_charge]
  end

  # --------------------------
  # SMS helpers (with nil safety)
  # --------------------------
  def send_invoice_sms(phone_number, due_date, invoice_number, username, plan_name, tenant)
    sms_setting = ActsAsTenant.current_tenant.sms_provider_setting
    return unless sms_setting&.sms_provider.present?

    case sms_setting.sms_provider
    when 'TextSms'
      send_expiration_text_sms(phone_number, due_date, invoice_number, username, plan_name, tenant)
    when 'SMS leopard'
      send_expiration_sms_leopard(phone_number, due_date, invoice_number, username, plan_name, tenant)
    else
      Rails.logger.info "No valid SMS provider configured"
    end
  end

  def send_expiration_sms_leopard(phone_number, due_date, invoice_number, username, plan_name, tenant)
    api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
    api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
    return unless api_key && api_secret

    message = "Hello #{username}, your invoice #{invoice_number} for #{plan_name} has been generated and is due on #{due_date.strftime('%B %d, %Y at %I:%M %p')}. Please renew your subscription to admin your network."

    uri = URI("https://api.smsleopard.com/v1/sms/send")
    params = {
      username: api_key,
      password: api_secret,
      message: message,
      destination: phone_number,
      source: "SMS_TEST"
    }
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    handle_sms_response(response, message, phone_number, tenant)
  end

  def send_expiration_text_sms(phone_number, due_date, invoice_number, username, plan_name, tenant)
    api_key = SmsSetting.find_by(sms_provider: 'TextSms')&.api_key
    partner_id = SmsSetting.find_by(sms_provider: 'TextSms')&.partnerID
    shortcode = SmsSetting.find_by(sms_provider: 'TextSms')&.sender_id
    return unless api_key && partner_id && shortcode

    message = "Hello #{username}, your invoice #{invoice_number} for #{plan_name} has been generated and is due on #{due_date.strftime('%B %d, %Y at %I:%M %p')}. Please renew your subscription to admin your network."

    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: api_key,
      message: message,
      mobile: phone_number,
      partnerID: partner_id,
      shortcode: shortcode
    }
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    handle_sms_response_text_sms(response, message, phone_number, tenant)
  end

  def handle_sms_response(response, message, phone_number, tenant)
    if response.is_a?(Net::HTTPSuccess)
      sms_data = JSON.parse(response.body)
        recipient = sms_data['responses'][0]['mobile']
        status = sms_data['responses'][0]['response-description']
        Rails.logger.info "SMS sent to #{recipient}, status: #{status}"

        SystemAdminSm.create!(
          user: recipient,
          message: message,
          status: status,
          date: Time.current,
          system_user: 'system',
          sms_provider: 'SMS leopard',
           account_id: tenant.id
        )
     
    else
      Rails.logger.info "HTTP error sending SMS: #{response.body}"
    end
  rescue => e
    Rails.logger.error "SMS handling error: #{e.message}"
  end







def handle_sms_response_text_sms(response, message, phone_number, tenant)
    if response.is_a?(Net::HTTPSuccess)
      sms_data = JSON.parse(response.body)
        recipient = sms_data['responses'][0]['mobile']
        status = sms_data['responses'][0]['response-description']
        Rails.logger.info "SMS sent to #{recipient}, status: #{status}"

        SystemAdminSm.create!(
          user: recipient,
          message: message,
          status: status,
          date: Time.current,
          system_user: 'system',
          sms_provider: 'SMS leopard',
           account_id: tenant.id
        )
     
    else
      Rails.logger.info "HTTP error sending SMS: #{response.body}"
    end
  rescue => e
    Rails.logger.error "SMS handling error: #{e.message}"
  end










  def generate_invoice_number
    "INV#{rand(100..999)}"
  end
end