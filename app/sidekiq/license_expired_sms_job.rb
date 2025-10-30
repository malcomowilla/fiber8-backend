class LicenseExpiredSmsJob
   include Sidekiq::Job
  queue_as :default

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        # Rails.logger.info "Processing plan invoice for => #{tenant.subdomain}"

                  

        if tenant.hotspot_plan&.name.present? && tenant.hotspot_plan.name != 'Free Trial'
                  # Rails.logger.info "Processing plan...... => #{tenant.subdomain}"
       
        if tenant.hotspot_plan&.expiry.present? && tenant.hotspot_plan.expiry < Time.current
           if hotspot_plan.last_invoiced_at.nil? || tenant.hotspot_plan.last_invoiced_at < tenant.hotspot_plan.expiry
          tenant.hotspot_plan.update!(last_invoiced_at: Time.current)
          process_hotspot_plan_invoice(tenant, tenant.hotspot_plan.name, tenant.hotspot_plan.price, 
          tenant.hotspot_plan.expiry_days)
           end
        end
      
        end
        


        # Process PPPoE plan
         if tenant.pp_poe_plan&.name.present? && tenant.pp_poe_plan.name != 'Free Trial'
         if tenant.pp_poe_plan&.expiry.present? && tenant.pp_poe_plan.expiry < Time.current
                     if tenant.pp_poe_plan&.last_invoiced_at.nil? || tenant.pp_poe_plan.last_invoiced_at < tenant.pp_poe_plan.expiry

                      tenant.pp_poe_plan.update!(last_invoiced_at: Time.current)
                      
          process_pppoe_plan_invoice(tenant, tenant.pp_poe_plan.name, tenant.pp_poe_plan.price, 
          tenant.pp_poe_plan.expiry_days)
        end
        end
      end
    



      end


    end



  end

  private





def process_hotspot_plan_invoice(tenant, plan_name, plan_amount, expiry_days)
    
Rails.logger.info "Processing hotspot plan invoice for => #{tenant.subdomain}"
      Invoice.create!(
        invoice_number: generate_invoice_number,
         invoice_date: Time.current,
        due_date: Time.current + expiry_days.days,
        invoice_desciption: "payment for hotspot license => #{plan_name}",
        total: plan_amount,
        status: "unpaid",
        account_id: tenant.id
      )
    
end






  def process_pppoe_plan_invoice(tenant, plan_name, plan_amount, expiry_days)
    Rails.logger.info "Processing PPPoE plan invoice for => #{tenant.subdomain}"

      Invoice.create!(
        invoice_number: generate_invoice_number,
         invoice_date: Time.current,
        due_date: Time.current + expiry_days.days,
        invoice_desciption: "payment for pppoe license => #{plan_name}",
        total: plan_amount,
        status: "unpaid",
        account_id: tenant.id,
      )
    
  end

  def generate_invoice_number
    "INV#{Time.current.strftime("%Y%m%d%H%M%S")}#{rand(100..999)}"
  end



def send_expiration_sms(phone_number, due_date, invoice_number, tenant)
    provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider
    

    case provider
    when 'TextSms'
      send_expiration_text_sms(phone_number, due_date, invoice_number)
    when 'SMS leopard'
      send_expiration(phone_number, due_date, invoice_number)
    else
      Rails.logger.info "No valid SMS provider configured"
    end
  end

  

  def send_expiration(phone_number, due_date, invoice_number, tenant, plan_name)

    # provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider

    api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
    api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
    

    sms_template = ActsAsTenant.current_tenant.sms_template
    # send_voucher_template = sms_template&.send_voucher_template
    original_message =  "Hello, #{tenant.users.where(role: "super_administrator").first.username} your invice #{invoice_number}  for #{plan_name} has been generated and is due to expire on #{due_date}. Please renew your subscription to stay connected."

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



  
  def send_expiration_text_sms(phone_number, due_date, invoice_number, tenant, plan_name)
    api_key = SmsSetting.find_by(sms_provider: 'TextSms')&.api_key
    partnerID = SmsSetting.find_by(sms_provider: 'TextSms')&.partnerID

    sms_template = ActsAsTenant.current_tenant.sms_template
    # send_voucher_template = sms_template&.send_voucher_template
        original_message =  "Hello, #{tenant.users.where(role: "super_administrator").first.username} your invoice #{invoice_number}  for #{plan_name} has been generated and is due to expire on #{due_date}. Please renew your subscription to stay connected."


    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: api_key,
      message: original_message,
      mobile: phone_number,
      partnerID: partnerID,
      shortcode: 'TextSMS',
      sms_provider: 'TextSms'

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
      Rails.logger.error "Failed to send message: #{response.body}"
    end
  end



  
end
