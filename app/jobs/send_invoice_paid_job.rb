
class SendInvoicePaidJob < ApplicationJob
  queue_as :default

  def perform(company_name, account_no, tenant, phone_number)
    # Loop all tenants
    ActsAsTenant.with_tenant(tenant) do
send_sms_for_tenant(company_name, account_no, ActsAsTenant.current_tenant)
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
    else
      Rails.logger.info "Tenant #{ActsAsTenant.current_tenant.id} has unknown SMS provider: #{sms_setting.sms_provider}"
    end
  end

  ##
  ## SMS Leopard
  ##
  def send_invoice_sms_leopard(company_name, account_no, tenant, phone_number)

     message = "Tnank you for your payment. Your invoice is now marked as paid at #{company_name || 'Aitechs'}. Account Number #{account_no}.
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

  ##
  ## TextSMS
  ##
  def send_invoice_text_sms(company_name, account_no, tenant, phone_number)

   
     message = "Tnank you for your payment. Your invoice is now marked as paid at #{company_name || 'Aitechs'}. Account Number #{account_no}.
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







                    