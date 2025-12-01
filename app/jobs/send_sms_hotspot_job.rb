class SendSmsHotspotJob < ApplicationJob
  queue_as :default

  def perform(voucher_code, data)
    # Loop all tenants
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
HotspotMpesaRevenue.create!(
      amount: data["TransAmount"],
      voucher: voucher_code,
      reference: data["TransID"],
      payment_method: "Mpesa",
      time_paid: data["TransTime"],
      account_id: ActsAsTenant.current_tenant.id
    )
        voucher = HotspotVoucher.find_by(voucher: voucher_code)
        next unless voucher # Skip if this tenant does NOT own this voucher

        send_sms_for_tenant(voucher, ActsAsTenant.current_tenant)
      end
    end
  end

  private

  def send_sms_for_tenant(voucher, tenant)
    sms_setting = tenant.sms_provider_setting


    if sms_setting.blank?
      Rails.logger.warn "Tenant #{ActsAsTenant.current_tenant.id} does not have an SMS provider set. Skipping SMS for voucher #{voucher.voucher}."
      return
    end

    case sms_setting.sms_provider
    when "SMS leopard"
      send_voucher_sms_leopard(voucher, tenant)
    when "TextSms"
      send_voucher_text_sms(voucher, tenant)
    else
      Rails.logger.warn "Tenant #{ActsAsTenant.current_tenant.id} has unknown SMS provider: #{sms_setting.sms_provider}. Skipping SMS for voucher #{voucher.voucher}."
    end
  end

  ##
  ## SMS Leopard
  ##
  def send_voucher_sms_leopard(voucher, tenant)
    message = "Your voucher code is: #{voucher.voucher}. This code is valid until #{voucher.expiration}."
sms_setting = tenant.sms_setting
  api_key = sms_setting.api_key
  api_secret = sms_setting.api_secret

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
    message = "Your voucher code is: #{voucher.voucher}. This code is valid until #{voucher.expiration}."
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
