class PlatformSendSmsService
  # Sends via the PLATFORM's TextSMS account (your creds), debits the
  # tenant's wallet. Tenant-facing error messages never mention TextSMS.
  #
  # Pricing/short_code have no ENV equivalent yet — set these two before
  # this goes live, or tell me where you'd rather they come from.
  SHORT_CODE = "TextSms"
  ENABLED  = ENV.fetch('PLATFORM_BULK_SMS_ENABLED', 'true') == 'true'

  def self.send_sms(phone_number, message, account_id)
    # return { success: false, error: 'SMS service unavailable' } unless ENABLED

    wallet = TenantSmsWallet.find_or_create_by!(account_id: account_id)
    return { success: false, error: 'Insufficient SMS balance' } if wallet.balance < 1

    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    uri.query = URI.encode_www_form(
      apikey: ENV['TEXT_SMS_API_KEY'],
      message: message,
      mobile: phone_number,
      partnerID: ENV['TEXTSMS_PARTNER_ID'],
      shortcode: SHORT_CODE
    )

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 5
    http.read_timeout = 8

    response = http.get(uri.request_uri)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      status = data.dig('responses', 0, 'response-description')
      wallet.debit!(1, reference: data.dig('responses', 0, 'messageid'))
         voucher.update(sms_sent: true)

      { success: true, status: status }

    else
      Rails.logger.error "PlatformBulkSmsService failed: #{response.body}"
      { success: false, error: 'Failed to send message' }
    end
  rescue Net::OpenTimeout, Net::ReadTimeout
    Rails.logger.error "PlatformBulkSmsService: TextSMS request timed out"
    { success: false, error: 'Failed to send message' }
  rescue => e
    Rails.logger.error "PlatformBulkSmsService error: #{e.message}"
    { success: false, error: e.message }
  end
end