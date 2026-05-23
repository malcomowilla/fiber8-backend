
class SendInvoicePaidJob < ApplicationJob
  queue_as :default

  def perform(company_name, account_no, tenant, phone_number)
    # Loop all tenants
    ActsAsTenant.with_tenant(tenant) do
send_sms_for_tenant(company_name, account_no, ActsAsTenant.current_tenant, phone_number)
    end

  end




  private

  def send_sms_for_tenant(company_name, account_no, tenant, phone_number)

    sms_setting = tenant.sms_provider_setting



    case sms_setting.sms_provider
    when "SMS leopard"
     send_invoice_sms_leopard(company_name, account_no, tenant, phone_number)
    when "TextSms"
     send_invoice_text_sms(company_name, account_no, tenant, phone_number)
    when "Talk Sasa"
      send_invoice_talksasa(company_name, account_no, tenant, phone_number)
    else
      Rails.logger.info "Tenant #{ActsAsTenant.current_tenant.id} has unknown SMS provider: #{sms_setting.sms_provider}"
    end
  end

  
  def send_invoice_sms_leopard(company_name, account_no, tenant, phone_number)

     message = "Thank you for your payment. Your invoice is now marked as paid at #{company_name || 'Aitechs'}. Account Number #{account_no}.
    "
sms_setting = tenant.sms_setting
  api_key = sms_setting.api_key
  api_secret = sms_setting.api_secret


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
    # Rails.logger.info "SMS Leopard response invoice #{invoice_number}: #{response.body}"
  end









  def send_invoice_talksasa(company_name, account_no, tenant, phone_number)

                          formatted_phone_number = "254#{phone_number.gsub(/\A0/, '')}"

  sms_setting = SmsSetting.find_by(sms_provider: 'Talk Sasa')

  api_key  = sms_setting&.api_key
  sender_id = sms_setting&.sender_id


  original_message = "Thank you for your payment. Your invoice is now marked as paid at #{company_name || 'Aitechs'}. Account Number #{account_no}."
    

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


   sms_status  = sms_data['status']


    SystemAdminSm.create!(
      user: phone_number,
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













  def send_invoice_text_sms(company_name, account_no, tenant, phone_number)

   
     message = "Thank you for your payment. Your invoice is now marked as paid at #{company_name || 'Aitechs'}. Account Number #{account_no}.
    "
  
sms_setting = tenant.sms_setting
  api_key = sms_setting.api_key
  partnerID = sms_setting.partnerID
    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: api_key,
      message: message,
      mobile: phone_number,
      partnerID: partnerID,
      shortcode: "TextSMS"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    # Rails.logger.info "TextSMS response invoice #{invoice_number}: #{response.body}"
  end
end







                    