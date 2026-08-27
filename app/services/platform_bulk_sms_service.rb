class PlatformBulkSmsService
  # Sends via the PLATFORM's TextSMS account (your creds), debits the
  # tenant's wallet. Tenant-facing error messages never mention TextSMS.
  def self.send_sms(phone_number, message, account_id)
    wallet = TenantSmsWallet.find_or_create_by!(account_id: account_id)
    return { success: false, error: 'Insufficient SMS balance' } if wallet.balance < 1

    setting = PlatformBulkSmsSetting.current
    return { success: false, error: 'SMS service unavailable' } unless setting.enabled

    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: setting.api_key, message: message, mobile: phone_number,
      partnerID: setting.partner_id, shortcode: setting.shortcode
    }
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      status = data.dig('responses', 0, 'response-description')
      wallet.debit!(1, reference: data.dig('responses', 0, 'messageid'))
      { success: true, status: status }
    else
      Rails.logger.error "PlatformBulkSmsService failed: #{response.body}"
      { success: false, error: 'Failed to send message' }
    end
  rescue => e
    Rails.logger.error "PlatformBulkSmsService error: #{e.message}"
    { success: false, error: e.message }
  end
end