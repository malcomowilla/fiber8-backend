class SendInvoiceJob < ApplicationJob
  queue_as :default

  def perform(company_name, phone_number, package_amount,
     due_date, paybill, account_no, tenant)
    # Loop all tenants
     
send_sms_for_tenant(company_name, phone_number, package_amount,
     due_date, paybill, account_no, tenant)
  end




  private

  def send_sms_for_tenant(company_name, phone_number, package_amount,
     due_date, paybill, account_no, tenant)

    sms_setting = tenant.sms_provider_setting



    case sms_setting.sms_provider
    when "SMS leopard"
     send_invoice_sms_leopard(company_name, phone_number, package_amount,
     due_date, paybill, account_no, tenant)
    when "TextSms"
     send_invoice_text_sms(company_name, phone_number, package_amount,
     due_date, paybill, account_no, tenant)
    else
      Rails.logger.info "Tenant #{ActsAsTenant.current_tenant.id} has unknown SMS provider: #{sms_setting.sms_provider}"
    end
  end

  ##
  ## SMS Leopard
  ##
  def send_invoice_sms_leopard(company_name, phone_number, package_amount,
     due_date, paybill, account_no, tenant)

     message = "Invoice for amount #{package_amount} KSh has been created For your #{company_name || 'Aitechs'} internet service. Due date: #{due_date},
    Payment: Mpesa Paybill: #{paybill}, Account No: #{account_no}
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
  def send_invoice_text_sms(company_name, phone_number, package_amount,
     due_date, paybill, account_no, tenant)

    message = "Invoice for amount #{package_amount} KSh has been created For your #{company_name || 'Aitechs'} internet service. Due date: #{due_date},
    Payment: Mpesa Paybill: #{paybill}, Account No: #{account_no}
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







                    