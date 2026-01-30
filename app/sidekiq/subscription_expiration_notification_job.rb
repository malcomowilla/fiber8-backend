

class SubscriptionExpirationNotificationJob
  include Sidekiq::Job
  queue_as :default


  def perform
      Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do

        expiration_reminder = SubscriberSetting.find_by(account_id: tenant.id)&.expiration_reminder
        next unless expiration_reminder
        expired_ppoe_subscriptions = Subscription
          .where("expiration_date <= ?", Time.current)
          .where(account_id: tenant.id)
          .where(expiration_sms_sent_at: nil) 

        next if expired_ppoe_subscriptions.empty?

        mpesa_setting = HotspotMpesaSetting.find_by(
          account_type: "Paybill",
          account_id: tenant.id
        )

        company_setting = CompanySetting.find_by(account_id: tenant.id)

        next unless mpesa_setting && company_setting

        paybill_number = mpesa_setting.short_code
        customer_support_phone_number = company_setting.customer_support_phone_number
        company_name = company_setting.company_name

        expired_ppoe_subscriptions.find_each do |subscription|
          subscriber = Subscriber.find_by(
            id: subscription.subscriber_id,
            account_id: tenant.id
          )

          next unless subscriber&.phone_number

          send_expiration_sms(
            subscriber.account_number,
            paybill_number,
            customer_support_phone_number,
            subscriber.phone_number,
            company_name,
            tenant
          )

          # ✅ mark as sent
          subscription.update_column(
            :expiration_sms_sent_at,
            Time.current
          )
        end
      end
    end
    
  end


private



  def send_expiration_sms(account_number, paybill_number, 
    customer_support_phone_number, phone_number, company_name,tenant)

    provider = tenant&.sms_provider_setting.present? && tenant.sms_provider_setting&.sms_provider
    

    case provider
    when 'TextSms'
      send_expiration_text_sms(account_number, paybill_number, 
    customer_support_phone_number, phone_number, company_name,tenant)
    when 'SMS leopard'
      send_expiration(account_number, paybill_number, 
    customer_support_phone_number, phone_number, company_name,tenant)
    else
      Rails.logger.info "No valid SMS provider configured"
    end
  end

  

  def send_expiration(account_number, paybill_number, 
    customer_support_phone_number, phone_number, company_name,tenant)

 settings = tenant&.sms_setting.present?  



if settings
api_secret_api_key = tenant&.sms_setting
  
  if api_secret_api_key.sms_provider == 'SMS leopard'
    
  api_key = api_secret_api_key&.api_key
  api_secret = api_secret_api_key&.api_secret
  end
  
    
end 


    sms_template = ActsAsTenant.current_tenant.sms_template
    send_voucher_template = sms_template&.send_voucher_template
    original_message = "Your service has been disconnected at #{company_name} for account #{account_number}. You can now make your #{company_name} payment via MPESA Paybill #{paybill_number} Account no: #{account_number}. For assistance call Telephone: #{customer_support_phone_number}"

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

  def send_expiration_text_sms(account_number, paybill_number, 
    customer_support_phone_number, phone_number, company_name,tenant)
    # api_key = SmsSetting.find_by(sms_provider: 'TextSms')&.api_key
    # partnerID = SmsSetting.find_by(sms_provider: 'TextSms')&.partnerID
# TextSms
    settings = tenant&.sms_setting.present?  
 
if settings
partner_id_api_key = tenant&.sms_setting
  
  if partner_id_api_key.sms_provider == 'TextSms'
    
  api_key = partner_id_api_key&.api_key
  partnerID = partner_id_api_key&.partnerID
  end
  
    
end 

    # partnerID = tenant&.sms_setting.present? && tenant.sms_setting.find_by(sms_provider: 'TextSms')&.partnerID
    sms_template = ActsAsTenant.current_tenant.sms_template
    send_voucher_template = sms_template&.send_voucher_template
    original_message = "Your service has been disconnected at #{company_name} for account #{account_number}. You can now make your #{company_name} payment via MPESA Paybill #{paybill_number} Account no: #{account_number}. For assistance call Telephone: #{customer_support_phone_number}"

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



