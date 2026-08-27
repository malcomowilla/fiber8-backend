class TenantSmsWalletMpesaService
  class << self
    def initiate_stk_push(phone_number, amount, account_reference, description)
      api_url = 'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'

      shortcode       = ENV['B2C_SHORTCODE']
      passkey         = ENV['PASSKEY']
      consumer_key    = ENV['CONSUMER_KEY']
      consumer_secret = ENV['CONSUMER_SECRET']

      formatted_phone_number = "254#{phone_number.to_s.gsub(/\A0/, '')}"

      token = fetch_access_token(api_url, consumer_key, consumer_secret)
      return { success: false, error: 'Failed to fetch access token' } unless token

      response = initiate_payment(
        token, shortcode, passkey, formatted_phone_number, amount,
        account_reference, description
      )
      { success: true, response: response }
    rescue => e
      Rails.logger.error("TenantSmsWalletMpesaService Error: #{e.message}")
      { success: false, error: e.message }
    end

    private

    def fetch_access_token(api_url, consumer_key, consumer_secret)
      response = RestClient.get(api_url, {
        params: { grant_type: 'client_credentials' },
        Authorization: "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}"
      })
      JSON.parse(response.body)['access_token']
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("TenantSmsWalletMpesaService: token error (HTTP #{e.http_code}): #{e.response&.body}")
      nil
    rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
      Rails.logger.error("TenantSmsWalletMpesaService: token request timed out")
      nil
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
      Rails.logger.error("TenantSmsWalletMpesaService: could not reach Safaricom (#{e.class}: #{e.message})")
      nil
    rescue => e
      Rails.logger.error("TenantSmsWalletMpesaService: #{e.class}: #{e.message}")
      nil
    end

    def initiate_payment(token, shortcode, passkey, formatted_phone_number, amount, account_reference, description)
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
      password  = Base64.strict_encode64("#{shortcode}#{passkey}#{timestamp}")

      payload = {
        BusinessShortCode: shortcode,
        Password: password,
        Timestamp: timestamp,
        TransactionType: "CustomerPayBillOnline",
        Amount: amount,
        PartyA: formatted_phone_number,
        PartyB: shortcode,
        PhoneNumber: formatted_phone_number,
        # NOT tenant-subdomain based — this is YOUR paybill's single
        # registered callback, same one check_payment_status already
        # handles for hotspot/invoice/pppoe via BillRefNumber prefix.
        # CallBackURL: "https://#{ENV['PLATFORM_CALLBACK_HOST']}/#{ENV['HOTSPOT_PAYMENTS']}",
        CallBackURL: "https://owitech.co.ke/tenant-sms",
        AccountReference: account_reference,
        TransactionDesc: description
      }

      
      response = RestClient.post(
        'https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest',
        payload.to_json,
        { content_type: :json, Authorization: "Bearer #{token}" }
      )
      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("TenantSmsWalletMpesaService: error initiating payment: #{e.response}")
      { error: 'Failed to initiate payment' }
    end
  end
end