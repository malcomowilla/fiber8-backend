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

        send_sms_for_tenant(voucher, expiration)
      end
    end
  end

  private

  def send_sms_for_tenant(voucher, expiration)
    sms_setting = ActsAsTenant.current_tenant.sms_provider_setting

    if sms_setting.blank?
      Rails.logger.warn "Tenant #{ActsAsTenant.current_tenant.id} does not have an SMS provider set. Skipping SMS for voucher #{voucher.voucher}."
      return
    end

    case sms_setting.sms_provider
    when "SMS leopard"
      send_voucher_sms_leopard(voucher, sms_setting, expiration)
    when "TextSms"
      send_voucher_text_sms(voucher, sms_setting, expiration)
    else
      Rails.logger.warn "Tenant #{ActsAsTenant.current_tenant.id} has unknown SMS provider: #{sms_setting.sms_provider}. Skipping SMS for voucher #{voucher.voucher}."
    end
  end

  ##
  ## SMS Leopard
  ##
  def send_voucher_sms_leopard(voucher, setting)
    message = "Your voucher code is: #{voucher.voucher}. This code is valid until #{voucher.expiration}."

    uri = URI("https://api.smsleopard.com/v1/sms/send")
    params = {
      username: setting.api_key,
      password: setting.api_secret,
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
  def send_voucher_text_sms(voucher, setting)
    message = "Your voucher code is: #{voucher.voucher}. This code is valid until #{voucher.expiration}."

    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: setting.api_key,
      message: message,
      mobile: voucher.phone,
      partnerID: setting.partnerID,
      shortcode: "TextSMS"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    Rails.logger.info "TextSMS response for voucher #{voucher.voucher}: #{response.body}"
  end
end
