

class SendSmsHotspotService
  

def self.send_sms(voucher_code, data,checkout_request_id)
   voucher = HotspotVoucher.find_by(voucher: voucher_code)

   
        # next unless voucher 
return unless voucher


# HotspotMpesaRevenue.create(
#       amount: data["TransAmount"],
#       voucher: voucher_code,
#       reference: data["TransID"],
#       payment_method: "Mpesa",
#       time_paid: data["TransTime"],
#       account_id: voucher.account_id,
#       name: data['FirstName'],
#       hotspot_voucher_id: voucher.id,

#     )
 revenue = HotspotMpesaRevenue.find_by(checkout_request_id: checkout_request_id)

if revenue
  revenue.update!(
    amount: data["TransAmount"],
    reference: data["TransID"],
    voucher: voucher_code,
    payment_method: "Mpesa",
    time_paid: data["TransTime"],
    name: data["FirstName"],
    account_id: voucher.account_id,
    status: "Completed",
    hotspot_voucher_id: voucher.id
  )
end

sms_sent_at_voucher = HotspotVoucher.find_by(voucher: voucher_code).sms_sent_at_voucher

account = Account.find_by(id: voucher.account_id)


if sms_sent_at_voucher.nil?
send_sms_for_tenant(voucher, account)
     

end

    
end



private
def self.send_sms_for_tenant(voucher, tenant)
    sms_setting = tenant.sms_provider_setting
  HotspotVoucher.find_by(voucher: voucher.voucher).update(sms_sent_at_voucher: Time.now, sms_sent: true)


    if sms_setting.blank?
      # Rails.logger.info "Tenant #{ActsAsTenant.current_tenant.id} does not have an SMS provider set. Skipping SMS for voucher #{voucher.voucher}."
      return
    end

    case sms_setting.sms_provider
    when "SMS leopard"
      send_voucher_sms_leopard(voucher, tenant)
    when "TextSms"
      send_voucher_text_sms(voucher, tenant)
    when "Talk Sasa"
      send_voucher_talksasa(voucher, tenant)

    else
      # Rails.logger.info "Tenant #{ActsAsTenant.current_tenant.id} has unknown SMS provider: #{sms_setting.sms_provider}. Skipping SMS for voucher #{voucher.voucher}."
    end
  end




 def self.send_voucher_talksasa(voucher, tenant)

                          formatted_phone_number = "254#{voucher.phone.gsub(/\A0/, '')}"

  sms_setting = SmsSetting.find_by(sms_provider: 'Talk Sasa')

  api_key  = sms_setting&.api_key
  sender_id = sms_setting&.sender_id


  original_message =  "Your voucher code is: #{voucher}. Enjoy your browsing"

  uri = URI.parse("https://bulksms.talksasa.com/api/v3/sms/send")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.request_uri)

  request["Authorization"] = "Bearer #{api_key}"
  request["Content-Type"] = "application/json"
  request["Accept"] = "application/json"

  request.body = {
    recipient: formatted_phone_number,
    sender_id: sender_id,
    type: "plain",
    message: original_message
  }.to_json

  response = http.request(request)

  Rails.logger.info "TalkSasa Response: #{response.body}"

  if response.is_a?(Net::HTTPSuccess)
    sms_data = JSON.parse(response.body)

    first_response = sms_data['responses']&.first

    sms_recipient = first_response&.dig('mobile')
   sms_status  = sms_data['status']

    Rails.logger.info "sms data =>: #{sms_data}, Status: #{sms_status}"

    SystemAdminSm.create!(
      user: voucher.phone,
      message: original_message,
      status: sms_status,
      date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
      system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Talk Sasa'
    )

    Rails.logger.info "Sent message successfully with talk sasa"
  else
    Rails.logger.info "Failed to send SMS with talk sasa : #{response.code} - #{response.body}"
  end
end















  def self.send_voucher_sms_leopard(voucher, tenant)
        expiration = voucher.expiration.strftime("%B %d, %Y at %I:%M %p") if voucher.expiration.present?

    # message = "Your voucher code is: #{voucher.voucher}. This code is valid until #{expiration}."


    message = "Your voucher code is: #{voucher.voucher} (FROM: )"
sms_setting = tenant.sms_setting
  api_key = sms_setting.api_key
  api_secret = sms_setting.api_secret


  HotspotVoucher.find_by(voucher: voucher.voucher).update(sms_sent_at_voucher: Time.now, sms_sent: true)
    uri = URI("https://api.smsleopard.com/v1/sms/send")
    params = {
      username: api_key,
      password: api_secret,
      message: message,
      destination: voucher.phone,
      source: "SMS_TEST"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
  sms_data = JSON.parse(response.body)

      sms_recipient = sms_data['responses'][0]['mobile']
      sms_status = sms_data['responses'][0]['response-description']


   SystemAdminSm.create!(
          user: sms_recipient,
          message: message,
          status: sms_status,
          date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
          system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Sms Leopard')
 else

   SystemAdminSm.create!(
          user: sms_recipient,
          message: message,
          status: sms_status,
          date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
          system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Sms Leopard')

 end

  end

  ##
  ## TextSMS
  ##
  def self.send_voucher_text_sms(voucher, tenant)
    expiration = voucher.expiration.strftime("%B %d, %Y at %I:%M %p") if voucher.expiration.present?

    message = "Your voucher code is: #{voucher.voucher}."
  # api_key = tenant.sms_setting.find_by(sms_provider: 'TextSms')&.api_key
  # partnerID = tenant.sms_setting.find_by(sms_provider: 'TextSms')&.partnerID

sms_setting = tenant.sms_setting
  api_key = sms_setting.api_key
  partnerID = sms_setting.partnerID
    shortcode = sms_setting.sender_id

    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: api_key,
      message: message,
      mobile: voucher.phone,
      partnerID: partnerID,
      shortcode:  shortcode
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
 if response.is_a?(Net::HTTPSuccess)
  sms_data = JSON.parse(response.body)

      sms_recipient = sms_data['responses'][0]['mobile']
      sms_status = sms_data['responses'][0]['response-description']


   SystemAdminSm.create!(
          user: sms_recipient,
          message: message,
          status: sms_status,
          date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
          system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Text Sms')
 else

   SystemAdminSm.create!(
          user: sms_recipient,
          message: message,
          status: sms_status,
          date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
          system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Text Sms')

 end

    # Rails.logger.info "TextSMS response for voucher #{voucher.voucher}: #{response.body}"
  end








end