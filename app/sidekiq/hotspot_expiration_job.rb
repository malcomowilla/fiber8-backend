class HotspotExpirationJob
  include Sidekiq::Job
  queue_as :default

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        expired_vouchers = HotspotVoucher.where("expiration <= ?", Time.current)


if expired_vouchers
 if ActsAsTenant.current_tenant.sms_provider_setting.sms_provider == 'TextSms'
          send_expiration_text_sms(voucher.phone, voucher.voucher)
        elsif ActsAsTenant.current_tenant.sms_provider_setting.sms_provider == 'SMS leopard'
          send_expiration(voucher.phone, voucher.voucher)
        end

end



        expired_vouchers.each do |voucher|
          logout_hotspot_user(voucher)
          voucher.update!(status: 'expired')  # Mark as expired in DB
        end
      end
    end
  end

  private

  def logout_hotspot_user(voucher)

    router_setting = ActsAsTenant.current_tenant&.router_setting&.router_name
    

    ip_address = NasRouter.find_by(name:router_setting)&.ip_address
    username = NasRouter.find_by(name:router_setting)&.username
    password = NasRouter.find_by(name:router_setting)&.password


    router_ip =  ip_address # Replace with your MikroTik router IP
    router_username = username
    router_password = password 

    remove_command = "/ip hotspot active remove [find user=#{voucher.voucher}]"

    begin
      Net::SSH.start(router_ip, router_username, password: router_password, verify_host_key: :never) do |ssh|
        output = ssh.exec!(remove_command)

       
        Rails.logger.info("Successfully removed user #{voucher.voucher}: #{output}")
      end
    rescue Net::SSH::AuthenticationFailed
      Rails.logger.error("SSH authentication failed for MikroTik router")
    rescue StandardError => e
      Rails.logger.error("Failed to logout user #{voucher.voucher}: #{e.message}")
    end
  end










  def send_expiration(phone_number, voucher_code
    )

    ActsAsTenant.current_tenant.sms_provider_setting.sms_provider

  api_key = SmsSetting.find_by(sms_provider: ActsAsTenant.current_tenant.sms_provider_setting.sms_provider)&.api_key
  api_secret = SmsSetting.find_by(sms_provider: ActsAsTenant.current_tenant.sms_provider_setting.sms_provider)&.api_secret
  
  
          api_key = api_key
          api_secret = api_secret
         
  
  
  sms_template =  ActsAsTenant.current_tenant.sms_template
  send_voucher_template = sms_template&.send_voucher_template
  original_message = sms_template ?  MessageTemplate.interpolate(send_voucher_template,{
    
  voucher_code: voucher_code,
  })  :   "Hello, your voucher #{voucher_code} is expired.
           "
  
  
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
              render json: { error: "Failed to send message: #{sms_data['message']}" }
            end
          else
            puts "Failed to send message: #{response.body}"
            # render json: { error: "Failed to send message: #{response.body}" }
          end
        end





       def send_expiration_text_sms(phone_number, voucher_code)
# sms_setting = SmsSetting.find_by(sms_provider: params[:selected_provider])

# if sms_setting.nil?
# render json: { error: "SMS provider not found" }, status: :not_found
# return
# end

api_key = SmsSetting.find_by(sms_provider: ActsAsTenant.current_tenant.sms_provider_setting.sms_provider)&.api_key
partnerID = SmsSetting.find_by(sms_provider: ActsAsTenant.current_tenant.sms_provider_setting.sms_provider)&.partnerID

# partnerID = sms_setting&.partnerID 

sms_template = ActsAsTenant.current_tenant.sms_template
send_voucher_template = sms_template&.send_voucher_template

original_message = if sms_template
MessageTemplate.interpolate(send_voucher_template, { voucher_code: voucher_code })
else
"Hello, your voucher #{voucher_code} is expired"
end

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

  

end
