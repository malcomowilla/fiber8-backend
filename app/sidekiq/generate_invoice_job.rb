# class GenerateInvoiceJob
#    include Sidekiq::Job
#     queue_as :invoices
#     sidekiq_options lock: :until_executed, lock_timeout: 0


    
#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
#         # Rails.logger.info "Processing plan invoice for => #{tenant.subdomain}"

#     Rails.logger.info "Processing hotspot and pppoe plan invoice for => #{tenant.subdomain}"


#         if tenant.hotspot_plan.present? && tenant.hotspot_plan&.name.present? && tenant.hotspot_plan.name != 'Hotspot Free Trial'

#         if tenant.hotspot_plan.present? && tenant.hotspot_plan&.expiry.present? && tenant.hotspot_plan&.expiry - 1.days < Time.current


#                     Rails.logger.info "Processing hotspot plan invoice for => #{tenant.subdomain}"

#    existing_invoice = tenant.invoices.where(plan_name: "Hotspot Plan #{tenant.hotspot_plan.name}").order(created_at: :desc).first

# if existing_invoice.nil? ||  existing_invoice.last_invoiced_at < 30.days.ago
#   process_hotspot_plan_invoice(
#     tenant,
#     tenant.hotspot_plan.name,
#     tenant.hotspot_plan.price,
#     tenant.hotspot_plan.expiry_days,
#     tenant.hotspot_plan.expiry
#   )

#   # send_expiration_sms(tenant.hotspot_plan.phone, tenant.hotspot_plan.expiry, existing_invoice.invoice_number, tenant)
# else
#     Rails.logger.info "Skipping invoice for #{tenant.subdomain} — already invoiced hotspot."
# end
#         end
#         end
        


#         # Process PPPoE plan
#          if tenant.pp_poe_plan.present? && tenant.pp_poe_plan&.name.present? && tenant.pp_poe_plan.name != 'PPPOE Free Trial'
#          if tenant.pp_poe_plan.present? && tenant.pp_poe_plan.expiry.present? && tenant.pp_poe_plan.expiry - 1.days < Time.current


#                     Rails.logger.info "Processing pppoe plan invoice for => #{tenant.subdomain}"


#    existing_invoice = tenant.invoices.where(plan_name: "PPPoE Plan #{tenant.pp_poe_plan.name}").order(created_at: :desc).first
#    

         

# if existing_invoice.nil? ||  existing_invoice.last_invoiced_at < 30.days.ago
#   process_pppoe_plan_invoice(
#     tenant,
#     tenant.pp_poe_plan.name,
#     tenant.pp_poe_plan.price,
#     tenant.pp_poe_plan.expiry_days,
#     tenant.pp_poe_plan.expiry
#   )

# else
#       Rails.logger.info "Skipping invoice for #{tenant.subdomain} — already invoiced ppoe."

# end
#         end
#       end
      



#       end


#     end



#   end

#   private





# def process_hotspot_plan_invoice(tenant, plan_name, plan_amount, expiry_days, expiry)
    
# Rails.logger.info "Processing hotspot plan invoice for => #{tenant.subdomain}"
# invoice = Invoice.create!(
#         invoice_number: generate_invoice_number,
#         plan_name: "Hotspot Plan #{plan_name}",
#          invoice_date: Time.current,
#         due_date: expiry - 1.days,
#         invoice_desciption: "payment for hotspot license => #{plan_name}",
#         total: plan_amount,
#         status: "unpaid",
#         account_id: tenant.id,
#         last_invoiced_at: Time.current,

#       )

#       # send_expiration_sms(phone_number, due_date, invoice_number, username, plan_name)
#        send_expiration_sms(tenant.users.where(role: "super_administrator").first.phone_number, invoice.due_date, invoice.invoice_number, tenant.users.where(role: "super_administrator").first.username, invoice.plan_name)
    
# end






#   def process_pppoe_plan_invoice(tenant, plan_name, plan_amount, expiry_days, expiry)
#     Rails.logger.info "Processing PPPoE plan invoice for => #{tenant.subdomain}"

#   invoice =  Invoice.create!(
#         invoice_number: generate_invoice_number,
#         plan_name: "PPPoE Plan #{plan_name}",
#         invoice_date: Time.current,
#         due_date: expiry - 1.days,
#         invoice_desciption: "payment for pppoe license => #{plan_name}",
#         total: plan_amount,
#         status: "unpaid",
#         account_id: tenant.id,
#         last_invoiced_at: Time.current,

#       )

#  send_expiration_sms(tenant.users.where(role: "super_administrator").first.phone_number, 
#  invoice.due_date, invoice.invoice_number,
#   tenant.users.where(role: "super_administrator").first.username, 
#   invoice.plan_name)

    
#   end




#   def generate_invoice_number
#     "INV#{rand(100..999)}"
#   end







#   def send_expiration_sms(phone_number, due_date, invoice_number, username, plan_name)
#     provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider
    

#     case provider
#     when 'TextSms'
#       send_expiration_text_sms(phone_number, due_date, invoice_number, username, plan_name)
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

#     sms_template = ActsAsTenant.current_tenant.sms_template
#     # send_voucher_template = sms_template&.send_voucher_template
#         original_message =  "Hello, #{username} your invoice #{invoice_number}  for #{plan_name} has been generated and is due on #{due_date.strftime("%B %d, %Y at %I:%M %p")}. Please renew your subscription to admin your network."


#     uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
#     params = {
#       apikey: api_key,
#       message: original_message,
#       mobile: phone_number,
#       partnerID: partnerID,
#       shortcode: 'TextSMS',
#       sms_provider: 'TextSms'

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
#       Rails.logger.error "Failed to send message: #{response.body}"
#     end
#   end


  


  
# end




class GenerateInvoiceJob
  include Sidekiq::Job
  queue_as :invoices

  SUBSCRIPTION_FEE = 500

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        # return unless tenant.hotspot_mpesa_setting.no_api_keys.nil?
        # tenant.hotspot_mpesa_setting.no_api_keys == false ? process_subscription_invoice(tenant) : nil
        setting = tenant.hotspot_mpesa_setting
    next if setting.nil?                     # skip tenants with no settings
    next if setting.no_api_keys == true      # skip if they use the "no API keys" mode
    # only reach here if setting exists and no_api_keys is false (i.e., they have API keys)
    process_subscription_invoice(tenant)
    
        # process_subscription_invoice(tenant)
      end
    end
  end

  private






  def process_subscription_invoice(tenant)
    plan = tenant.hotspot_and_dial_plan
    return unless plan.present?
    return unless plan.expiry.present?
    # return unless plan.name == "Free Trial"
    # ✅ Trigger 5 days before expiry
    return unless plan.expiry - 5.days <= Time.current

    # last_invoice = tenant.invoices.where(plan_name: "Subscription Fee").order(created_at: :desc).first
    last_invoice = tenant.invoices.where(status: 'unpaid').order(created_at: :desc).first

    # ✅ Prevent duplicate invoices
    if last_invoice&.last_invoiced_at.present? &&
       last_invoice.last_invoiced_at > 25.days.ago
      Rails.logger.info "Skipping invoice for #{tenant.subdomain}"
      return
    end

    create_subscription_invoice(tenant, plan)
  end

  def create_subscription_invoice(tenant, plan)
    invoice = Invoice.create!(
      invoice_number: generate_invoice_number,
      plan_name: "Subscription Fee",
      invoice_date: Time.current,
      due_date: plan.expiry,
      invoice_desciption: {
        summary: "Monthly Subscription",
        items: [
          {
            description: "System Access Fee",
            details: "Monthly ISP billing platform access",
            amount: SUBSCRIPTION_FEE,
            currency: "KES"
          }
        ]
      }.to_json,
      total: SUBSCRIPTION_FEE,
      status: "unpaid",
      account_id: tenant.id,
      last_invoiced_at: Time.current
    )

    send_invoice_sms(
      tenant.users.where(role: "super_administrator").first.phone_number,
      invoice.due_date,
      invoice.invoice_number,
      tenant.users.where(role: "super_administrator").first.username,
      invoice.plan_name
    )
  end









  def send_invoice_sms(phone_number, due_date, 
    invoice_number, username, plan_name)
    provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider
    

    case provider
    when 'TextSms'
      send_expiration_text_sms(phone_number, due_date, invoice_number, 
      username, plan_name)
    when 'SMS leopard'
      send_expiration(phone_number, due_date, invoice_number, username, plan_name)
    else
      Rails.logger.info "No valid SMS provider configured"
    end
  end





def send_expiration(phone_number, due_date, invoice_number, 
    
  endusername, plan_name)

    # provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider

    api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
    api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
    

    sms_template = ActsAsTenant.current_tenant.sms_template
    # send_voucher_template = sms_template&.send_voucher_template
    original_message =  "Hello, #{username} your invoice #{invoice_number}  for #{plan_name} has been generated and is due on #{due_date.strftime("%B %d, %Y at %I:%M %p")}. Please renew your subscription to admin your network."

    sender_id = "SMS_TEST"
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
    handle_sms_response(response, original_message, phone_number)
  end



  
  def send_expiration_text_sms(phone_number, due_date, invoice_number, 
    username, plan_name)
    api_key = SmsSetting.find_by(sms_provider: 'TextSms')&.api_key
    partnerID = SmsSetting.find_by(sms_provider: 'TextSms')&.partnerID
    shortcode = SmsSetting.find_by(sms_provider: 'TextSms')&.sender_id

    sms_template = ActsAsTenant.current_tenant.sms_template
    # send_voucher_template = sms_template&.send_voucher_template
        original_message =  "Hello, #{username} your invoice #{invoice_number}  for #{plan_name} has been generated and is due on #{due_date.strftime("%B %d, %Y at %I:%M %p")}. Please renew your subscription to admin your network."


    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: api_key,
      message: original_message,
      mobile: phone_number,
      partnerID: partnerID,
      shortcode: shortcode,

    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    handle_sms_response(response, original_message, phone_number)
  end






   def handle_sms_response(response, message, phone_number)
    if response.is_a?(Net::HTTPSuccess)
      sms_data = JSON.parse(response.body)
      if sms_data['responses'] && sms_data['responses'][0]['respose-code'] == 200
        sms_recipient = sms_data['responses'][0]['mobile']
        sms_status = sms_data['responses'][0]['response-description']
        
        Rails.logger.info "Recipient: #{sms_recipient}, Status: #{sms_status}"

        SystemAdminSm.create!(
          user: sms_recipient,
          message: message,
          status: sms_status,
          date: Time.current,
          system_user: 'system',
          sms_provider: 'SMS leopard'
        )
      else
        Rails.logger.info "Failed to send message: #{sms_data['responses'][0]['response-description']}"
      end
    else
      Rails.logger.info "Failed to send message: #{response.body}"
    end
  end







  def generate_invoice_number
    "INV#{SecureRandom.hex(3).upcase}"
  end
end