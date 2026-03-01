
class HotspotExpirationJob
  include Sidekiq::Job
  queue_as :default
     sidekiq_options lock: :until_executed, lock_timeout: 0


  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do


        # expired_vouchers = HotspotVoucher.where("expiration <= ? AND status != ?", Time.current, 'expired')
        # expired_vouchers = HotspotVoucher.where('expiration <= ?', Time.current)
# expired_vouchers = tenant&.hotspot_vouchers&.present? && tenant&.hotspot_vouchers&.where('expiration < ?', Time.current)

 hotspot_subscriptions = HotspotVoucher.where(account_id: tenant.id)





hotspot_subscriptions.find_each do |subscription|
  next unless subscription.voucher.present?

  # Fetch the PPPoE plan linked to this subscription/account
  plan = tenant&.hotspot_and_dial_plan

  expired_hotspot = plan&.expiry.present? && plan.expiry <= Time.current
  empty_expiry = subscription.expiration.nil?

# expiry_voucher = HotspotSetting.find_by(account_id: tenant.id).voucher_expiration

  if empty_expiry
    calculate_expiration_voucher(subscription.package, subscription, subscription.account_id)
    
  end
  
  if  expired_hotspot
    # Deny login by adding reject if not already there
    RadCheck.find_or_create_by!(
      username: subscription.voucher,
      radiusattribute: 'Auth-Type',
      account_id: subscription.account_id,
      op: ':=',
      value: 'Reject'
    )
  else
    # Allow login by removing the reject entry if it exists
    RadCheck.where(
      username: subscription.voucher,
      account_id: subscription.account_id,
      radiusattribute: 'Auth-Type',
      value: 'Reject'
    ).destroy_all
  end
end



expired_vouchers = HotspotVoucher.where('expiration < ?', Time.current).where(account_id: tenant.id)
# return unless expired_vouchers.present?
       
     
        expired_vouchers.find_each do |voucher|

          voucher.update!(status: 'expired') # Mark as expired in DB
         
          


          # Only send SMS if it hasn't been sent before
          if voucher.sms_sent_at.nil? && voucher.used_voucher  
             send_expiration_sms(voucher, tenant) # Unified function to send SMS based on provider
             voucher.update!(sms_sent_at: Time.current) # Track when the SMS was sent
          end
#  logout_hotspot_user(voucher, tenant)
        end
      end
    end
  end

  private


def calculate_expiration_voucher(package, voucher_created, account_id)
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
    voucher_created.update(expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),)
  end

  # Return both expiration and status
  {
    expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p"),
  }
end




  def logout_hotspot_user(voucher, tenant)
  NasRouter.where(account_id: tenant.id).find_each do |router|
    router_ip = router.ip_address
    router_username = router.username
    router_password = router.password 

    remove_command = "/ip hotspot active remove [find user=#{voucher.voucher}]"

    begin
      Net::SSH.start(router_ip, router_username, password: router_password, verify_host_key: :never, non_interactive: true) do |ssh|
        output = ssh.exec!(remove_command)
        Rails.logger.info("Successfully removed user #{voucher.voucher} from router #{router.name || router_ip}: #{output}")
      end
    rescue Net::SSH::AuthenticationFailed
      Rails.logger.error("SSH authentication failed for MikroTik router #{router.name || router_ip}")
    rescue StandardError => e
      Rails.logger.error("Failed to logout user #{voucher.voucher} from router #{router.name || router_ip}: #{e.message}")
    end
  end
end


  def send_expiration_sms(voucher, tenant)
    provider = tenant&.sms_provider_setting.present? && tenant.sms_provider_setting&.sms_provider
    phone_number = voucher.phone
    voucher_code = voucher.voucher

    case provider
    when 'TextSms'
      send_expiration_text_sms(phone_number, voucher_code, tenant)
    when 'SMS leopard'
      send_expiration(phone_number, voucher_code, tenant)
    else
      Rails.logger.info "No valid SMS provider configured"
    end
  end

  

  def send_expiration(phone_number, voucher_code, tenant)

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
    original_message = sms_template ? MessageTemplate.interpolate(send_voucher_template, { voucher_code: voucher_code }) : "Hello, your voucher #{voucher_code} is expired renew now to stay conected."

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

  def send_expiration_text_sms(phone_number, voucher_code, tenant)
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
    original_message = sms_template ? MessageTemplate.interpolate(send_voucher_template,
     { voucher_code: voucher_code }) : "Hello, your voucher #{voucher_code} is expired renew now to stay conected."

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


