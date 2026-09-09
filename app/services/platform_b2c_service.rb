class PlatformB2cService
  def self.disburse(phone_number, amount)
    token = fetch_access_token
    return false unless token

    payload = {
      OriginatorConversationID: SecureRandom.uuid,
      InitiatorName: ENV['REFERRAL_B2C_INITIATOR_USERNAME'],
      SecurityCredential: ENV['REFERRAL_B2C_INITIATOR_PASSWORD'],
      CommandID: 'BusinessPayment',
      Amount: amount,
      PartyA: ENV['REFERRAL_B2C_SHORTCODE'],
      PartyB: format_phone(phone_number),
      Remarks: 'Referral reward',
      QueueTimeOutURL: "https://#{ENV['HOST']}/referral_disburse_results_timeout",
      ResultURL: "https://#{ENV['HOST']}/referral_disburse_results",
      Occassion: 'ReferralReward'
    }

    response = RestClient.post(
      'https://api.safaricom.co.ke/mpesa/b2c/v1/paymentrequest',
      payload.to_json,
      { content_type: :json, Authorization: "Bearer #{token}" }
    )
    parsed = JSON.parse(response.body)
    parsed['ResponseCode'] == '0'
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Referral B2C exception: #{e.response.body}"
    false
  rescue => e
    Rails.logger.error "Referral B2C error: #{e.message}"
    false
  end

  def self.fetch_access_token
    response = RestClient.get(
      'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials',
      Authorization: "Basic #{Base64.strict_encode64("#{ENV['REFERRAL_B2C_CONSUMER_KEY']}:#{ENV['REFERRAL_B2C_CONSUMER_SECRET']}")}"
    )
    JSON.parse(response.body)['access_token']
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Referral B2C token error: #{e.response.body}"
    nil
  end

  def self.format_phone(phone)
    digits = phone.to_s.strip.gsub(/\D/, '')
    case digits
    when /\A0\d{9}\z/ then digits.sub(/\A0/, '254')
    when /\A254\d{9}\z/ then digits
    when /\A7\d{8}\z/, /\A1\d{8}\z/ then "254#{digits}"
    else digits
    end
  end
end