


class HotspotCompensationJob 
  include Sidekiq::Job
  queue_as :default

 def perform
  Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        company_name = tenant.company_setting&.company_name
        hotspot_vouchers = HotspotVoucher.joins(:temporary_sessions).where(
          
          temporary_sessions: { connected: false,
          paid: false,
        
        },
        status: 'active', 
        account_id: tenant.id)

        hotspot_vouchers.each do |hotspot_voucher|
          enable_compensation = tenant.hotspot_customization.enable_compensation

          if enable_compensation == true && hotspot_voucher.sent_sms_compensation == false
            send_notification_sms_compensation(hotspot_voucher.phone, 
            tenant, company_name, hotspot_voucher)
            compensate_hotspot_voucher(hotspot_voucher, tenant)
          end
          
        end

      end
      end
 end
 


 def send_notification_sms_compensation(phone_number, tenant, 
 company_name, voucher)

   HotspotVoucher.find_by(voucher: voucher.voucher).update(
    sent_sms_compensation: true
    )

    provider = tenant&.sms_provider_setting.present? && tenant.sms_provider_setting&.sms_provider

    case provider
    when 'TextSms'
      send_notification_text_sms_compensation(phone_number, tenant,
       company_name, voucher)
    when 'SMS leopard'
      send_notification_sms_leopard_compensation(phone_number, 
       tenant, company_name, voucher)
    else
      Rails.logger.info "No valid SMS provider configured"
    end
  end


private


def compensate_hotspot_voucher(voucher, tenant)
  hotspot_voucher = HotspotVoucher.find_by(voucher: voucher.voucher)
  voucher_expiration = tenant.hotspot_setting.voucher_expiration

  if voucher_expiration == 'Expiry After Creation'
   create_voucher_radcheck(hotspot_voucher,tenant)
   calculate_expiration(voucher.package, voucher, tenant)
    
  end

end




 def create_voucher_radcheck(hotspot_voucher,tenant)

hotspot_package = "hotspot_#{tenant.id}_#{hotspot_voucher.package.parameterize(separator: '_')}"

radcheck = RadCheck.find_or_initialize_by(username: hotspot_voucher.voucher,
account_id: tenant.id,
radiusattribute: 
'Cleartext-Password')  

radcheck.update!(op: ':=', value: hotspot_voucher)

rad_user_group = RadUserGroup.find_or_initialize_by(username: hotspot_voucher,
 groupname: hotspot_package, priority: 1, account_id: tenant.id)
rad_user_group.update!(username: hotspot_voucher, groupname: hotspot_package, priority: 1)


rad_reply = RadReply.find_or_initialize_by(username: hotspot_voucher, 
radiusattribute: '',
account_id: tenant.id,
 op: ':=', value: '5000')
 
rad_reply.update!(username: hotspot_voucher, 
radiusattribute: 'Idle-Timeout', op: ':=', value: '5000')

validity_period_units = HotspotPackage.find_by(name: hotspot_voucher.package, account_id: tenant.id).validity_period_units
validity = HotspotPackage.find_by(name: hotspot_voucher.package, account_id: tenant.id).validity


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
formatted_expiration = final_expiration.strftime("%d %b %Y %H:%M:%S")

if final_expiration
  rad_check = RadCheck.find_or_initialize_by(
    username: hotspot_voucher,
    account_id: account_id,
    radiusattribute: 'Expiration'
  )

  rad_check.update!(op: ':=', value: formatted_expiration)
end
end
  






def calculate_expiration(package, voucher, tenant)

   hotspot_package = HotspotPackage.find_by(name: package, 
  account_id: tenant.id)
    hotspot_voucher = HotspotVoucher.find_by(voucher: voucher.voucher)


Rails.logger.info "Hotspot Package Not Found" unless hotspot_package
  
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

  else
    nil
  end

 extra_time = compensation_duration(tenant)
 final_expiration = expiration_time + extra_time


  if expiration_time.present?
      hotspot_voucher.update(
    expiration: final_expiration.strftime("%B %d, %Y at %I:%M %p")
  )
  end

end







def compensation_duration(tenant)
  customization = tenant.hotspot_customization

  return 0 unless customization&.enable_compensation

  if customization.compensation_minutes.present?
    customization.compensation_minutes.minutes
  elsif customization.compensation_hours.present?
    customization.compensation_hours.hours
  else
    0
  end
end




def send_notification_sms_leopard_compensation(phone_number,tenant,
    company_name, voucher)

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
original_message =  "Sorry for earlier connection issue. Service is now restored and we’ve added bonus time to your account. 
    Please reconnect with your voucher (#{voucher.voucher}). Thank you 🙏, (FROM:  #{company_name})
"
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
    handle_sms_response_sms_leopard(response, original_message, phone_number, tenant)
  end





  def send_notification_text_sms_compensation(phone_number,tenant, 
    company_name, voucher)
    # api_key = SmsSetting.find_by(sms_provider: 'TextSms')&.api_key
    # partnerID = SmsSetting.find_by(sms_provider: 'TextSms')&.partnerID
# TextSms
    settings = tenant&.sms_setting.present?  
 
if settings
partner_id_api_key = tenant&.sms_setting
  
  if partner_id_api_key.sms_provider == 'TextSms'
    
  api_key = partner_id_api_key&.api_key
  partnerID = partner_id_api_key&.partnerID
    shortcode = partner_id_api_key&.sender_id

  end
  
    
end 

    # partnerID = tenant&.sms_setting.present? && tenant.sms_setting.find_by(sms_provider: 'TextSms')&.partnerID
    sms_template = ActsAsTenant.current_tenant.sms_template
    send_voucher_template = sms_template&.send_voucher_template
    original_message =  "Sorry for earlier connection issue. Service is now restored and we’ve added bonus time to your account. 
    Please reconnect with your voucher (#{voucher.voucher}). Thank you 🙏, (FROM:  #{company_name})
"

    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: api_key,
      message: original_message,
      mobile: phone_number,
      partnerID: partnerID,
      shortcode: shortcode,
      # sms_provider: 'TextSms'

    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    handle_sms_response_text_sms(response, original_message, phone_number, tenant)
  end





  def handle_sms_response_sms_leopard(response, message, 
    phone_number, tenant)
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
          sms_provider: 'SMS leopard',
          account_id: tenant.id
        )
      else
        Rails.logger.info "Failed to send message: #{sms_data['responses'][0]['response-description']}"
      end
    else
      Rails.logger.info "Failed to send message: #{response.body}"
    end
  end




 def handle_sms_response_text_sms(response, message, phone_number, tenant)
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
          sms_provider: 'Text SMS',
          account_id: tenant.id
        )
      else
        Rails.logger.info "Failed to send message: #{sms_data['responses'][0]['response-description']}"
      end
    else
      Rails.logger.info "Failed to send message: #{response.body}"
    end
  end







end