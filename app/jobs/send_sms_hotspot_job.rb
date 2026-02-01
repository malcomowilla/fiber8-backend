class SendSmsHotspotJob < ApplicationJob
  queue_as :default

  def perform(voucher_code, data)
      voucher = HotspotVoucher.find_by(voucher: voucher_code)
      ActsAsTenant.with_tenant(voucher.account) do

   
        next unless voucher # Skip if this tenant does NOT own this voucher

sms_sent_at_voucher = HotspotVoucher.find_by(voucher: voucher.voucher).sms_sent_at_voucher


if sms_sent_at_voucher.nil?
send_sms_for_tenant(voucher, ActsAsTenant.current_tenant)
     
HotspotMpesaRevenue.find_or_create_by(
      amount: data["TransAmount"],
      voucher: voucher_code,
      reference: data["TransID"],
      payment_method: "Mpesa",
      time_paid: data["TransTime"],
      account_id: voucher.account_id,

      name: data['FirstName']
    )
end


        
    
    end
  end

  private

  def send_sms_for_tenant(voucher, tenant)
    sms_setting = tenant.sms_provider_setting
  HotspotVoucher.find_by(voucher: voucher.voucher).update(sms_sent_at_voucher: Time.now, sms_sent: true)


    if sms_setting.blank?
      Rails.logger.info "Tenant #{ActsAsTenant.current_tenant.id} does not have an SMS provider set. Skipping SMS for voucher #{voucher.voucher}."
      return
    end

    case sms_setting.sms_provider
    when "SMS leopard"
      send_voucher_sms_leopard(voucher, tenant)
    when "TextSms"
      send_voucher_text_sms(voucher, tenant)
    else
      Rails.logger.info "Tenant #{ActsAsTenant.current_tenant.id} has unknown SMS provider: #{sms_setting.sms_provider}. Skipping SMS for voucher #{voucher.voucher}."
    end
  end



  def send_voucher_sms_leopard(voucher, tenant)
        expiration = voucher.expiration.strftime("%B %d, %Y at %I:%M %p") if voucher.expiration.present?

    message = "Your voucher code is: #{voucher.voucher}. This code is valid until #{expiration}."
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
    Rails.logger.info "SMS Leopard response for voucher #{voucher.voucher}: #{response.body}"
  end

  ##
  ## TextSMS
  ##
  def send_voucher_text_sms(voucher, tenant)
    expiration = voucher.expiration.strftime("%B %d, %Y at %I:%M %p") if voucher.expiration.present?

    message = "Your voucher code is: #{voucher.voucher}. This code is valid until #{expiration}."
  # api_key = tenant.sms_setting.find_by(sms_provider: 'TextSms')&.api_key
  # partnerID = tenant.sms_setting.find_by(sms_provider: 'TextSms')&.partnerID

sms_setting = tenant.sms_setting
  api_key = sms_setting.api_key
  partnerID = sms_setting.partnerID
    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: api_key,
      message: message,
      mobile: voucher.phone,
      partnerID: partnerID,
      shortcode: "TextSMS"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    Rails.logger.info "TextSMS response for voucher #{voucher.voucher}: #{response.body}"
  end
end







                    