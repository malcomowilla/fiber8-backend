
require 'open3'
class RouterNotificationJob
  include Sidekiq::Job
  queue_as :default
   sidekiq_options lock: :until_executed, lock_timeout: 0


  def perform

    Account.find_each do |tenant| # Iterate over all tenants
      ActsAsTenant.with_tenant(tenant) do
        
notification_when_unreachable = tenant&.nas_setting&.notification_when_unreachable
# unreachable_duration_minutes = tenant&.nas_setting&.unreachable_duration_minutes
notification_phone_number = tenant&.nas_setting&.notification_phone_number

if notification_when_unreachable
        nas_routers = NasRouter.all
        nas_routers.each do |nas_router|
  ip_address = nas_router.ip_address
  router_name = nas_router.name # Make sure you have router name

  Rails.logger.info "Pinging router at #{ip_address} for tenant #{tenant.id}..."

  output, status = Open3.capture2e("ping -c 3 #{ip_address}")
  reachable = status.success?
  new_status = reachable ? "reachable" : "unreachable"

  now = Time.current

  # Update last_status_changed_at if status changed
  if nas_router.last_status != new_status
    nas_router.update(
      last_status: new_status,
      last_status_changed_at: now
    )
  end

  # Check if we should send notification
  duration = tenant&.nas_setting&.unreachable_duration_minutes || 0
  minutes_since_change = (now - (nas_router.last_status_changed_at || now)) / 60.0
  notification_sent = nas_router.last_notification_sent_at

  if minutes_since_change >= duration
    # Avoid sending multiple notifications for same status
    if notification_sent.nil? || notification_sent < nas_router.last_status_changed_at
      if new_status == "reachable"
        send_notification_sms_reachable(notification_phone_number, tenant, router_name,
         ip_address)
      else
        send_notification_sms_unreachable(notification_phone_number, tenant,
         router_name, ip_address)
      end

      nas_router.update(last_notification_sent_at: now)
    end
  end
end

      end


      end
      end


    
  end

private
def send_notification_sms_reachable(phone_number, tenant, router_name, ip_address)
    provider = tenant&.sms_provider_setting.present? && tenant.sms_provider_setting&.sms_provider

    case provider
    when 'TextSms'
      send_notification_text_sms_reachable(phone_number, tenant, router_name, ip_address)
    when 'SMS leopard'
      send_notification_sms_leopard_reachable(phone_number, tenant, router_name, ip_address)
    else
      Rails.logger.info "No valid SMS provider configured"
    end
  end






  def send_notification_sms_unreachable(phone_number, tenant, router_name, ip_address)
    provider = tenant&.sms_provider_setting.present? && tenant.sms_provider_setting&.sms_provider

    case provider
    when 'TextSms'
      send_notification_text_sms_unreachable(phone_number, tenant, router_name, ip_address)
    when 'SMS leopard'
      send_notification_sms_leopard_unreachable(phone_number, tenant, router_name,  ip_address)
    else
      Rails.logger.info "No valid SMS provider configured"
    end
  end




def send_notification_sms_leopard_unreachable(phone_number,tenant,router_name, ip_address)

    # provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider

    # api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
    # api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
    # api_key = tenant&.sms_setting.present? && tenant.sms_setting.find_by(sms_provider: 'SMS leopard')&.api_key
    # api_secret = tenant&.sms_setting.present? && tenant.sms_setting.find_by(sms_provider: 'SMS leopard')&.api_secret

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
    # original_message = sms_template ? MessageTemplate.interpolate(send_voucher_template, { voucher_code: voucher_code }) : "Hello, your voucher #{voucher_code} is expired renew now to stay conected."
    original_message =  "Hello, your router=> #{ip_address}, router name=>#{router_name} is unreachable"

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
    handle_sms_response_sms_leopard(response, original_message, phone_number)
  end






  def send_notification_text_sms_unreachable(phone_number,tenant,router_name, ip_address)
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
    original_message =  "Hello, your router=> #{ip_address}, router name=> #{router_name} is unreachable"

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
    handle_sms_response_text_sms(response, original_message, phone_number)
  end





  def send_notification_sms_leopard_reachable(phone_number,tenant,router_name, ip_address)

    # provider = ActsAsTenant.current_tenant.sms_provider_setting.sms_provider

    # api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
    # api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret
    # api_key = tenant&.sms_setting.present? && tenant.sms_setting.find_by(sms_provider: 'SMS leopard')&.api_key
    # api_secret = tenant&.sms_setting.present? && tenant.sms_setting.find_by(sms_provider: 'SMS leopard')&.api_secret

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
    # original_message = sms_template ? MessageTemplate.interpolate(send_voucher_template, { voucher_code: voucher_code }) : "Hello, your voucher #{voucher_code} is expired renew now to stay conected."
    original_message =  "Hello, your router #{ip_address}, router name #{router_name} is reachable"

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
    handle_sms_response_text_sms(response, original_message, phone_number)
  end





  def send_notification_text_sms_reachable(phone_number,tenant, router_name, ip_address)
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
    original_message =  "Hello, your router #{ip_address}, router name #{router_name} is reachable"

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
    handle_sms_response_sms_leopard(response, original_message, phone_number)
  end





  def handle_sms_response_sms_leopard(response, message, phone_number)
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




 def handle_sms_response_text_sms(response, message, phone_number)
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
          sms_provider: 'Text SMS'
        )
      else
        Rails.logger.info "Failed to send message: #{sms_data['responses'][0]['response-description']}"
      end
    else
      Rails.logger.info "Failed to send message: #{response.body}"
    end
  end




end