class MpesaService

  class << self



    def initiate_stk_push(phone_number, amount, shortcode,  passkey,
       consumer_key, consumer_secret, host, voucher_code) 
      # api_url = 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'
    api_url = 'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'

    
      consumer_key = consumer_key
      consumer_secret = consumer_secret
      shortcode = shortcode
      callback_url= "https://malcomowilla.github.io/my-portfolio/"   
    
      lipa_na_mpesa_online_passkey =  passkey;
      
      
      phone_number = phone_number = phone_number
      formatted_phone_number = "254#{phone_number.gsub(/\A0/, '')}"
    
      # permitted_params = params.permit(:amount, :phone_number) 
      amount = amount
    
      # Rails.logger.info("Received parameters: #{params}")
    
    
    
    
    
     token = fetch_access_token(api_url, consumer_key, consumer_secret, voucher_code)
     
    
    #  if token
    #   response = initiate_payment(api_url, token, shortcode, lipa_na_mpesa_online_passkey, callback_url, formatted_phone_number, amount)
    #   render json: response
    # else
    #   render json: { error: 'Failed to fetch access token' }, status: :unprocessable_entity
    # end
    
    
    # end
    

    if token
      # Initiate payment
      response = initiate_payment(api_url, token, shortcode, passkey, callback_url,
       formatted_phone_number, amount,
      host, voucher_code
      )
      { success: true, response: response }
    else
      { success: false, error: 'Failed to fetch access token' }
    end
  rescue => e
    Rails.logger.error("MpesaService Error: #{e.message}")
    { success: false, error: e.message }
  end



    private

    def fetch_access_token(api_url, consumer_key, consumer_secret, voucher_code)
      
      response = RestClient.get(api_url, { params: { grant_type: 'client_credentials' }, Authorization: "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}" })
    
      body = response.body
      Rails.logger.info("OAuth Response Body: #{body}")
      access_token = JSON.parse(response.body)['access_token']
    
    access_token
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Error fetching access token: #{e.response}")
      nil
    end
    
    
    
    def initiate_payment(api_url, token, shortcode, lipa_na_mpesa_online_passkey, callback_url,
       formatted_phone_number, amount, host, voucher_code)
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    
      password = Base64.strict_encode64("#{shortcode}#{lipa_na_mpesa_online_passkey}#{timestamp}")
    
    
      Rails.logger.info("Payment Request Timestamp: #{timestamp}")
      Rails.logger.info("Payment Request Password: #{password}")
    

      
    payload = {    
      BusinessShortCode: shortcode,    
      Password:  password,    
      Timestamp:timestamp,    
      TransactionType: "CustomerPayBillOnline",    
      Amount: amount,    
      PartyA: formatted_phone_number,    
      PartyB: shortcode ,    
      PhoneNumber:formatted_phone_number,     
      CallBackURL: "https://#{host}.#{ENV['HOST']}/#{ENV['HOTSPOT_PAYMENTS']}",    
      AccountReference: voucher_code,    
      TransactionDesc:"Testing stk push"
    }
    

    Rails.logger.info("Payment Request Payload: #{payload}")
    
    response = RestClient.post(
      # "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      'https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest',
      payload.to_json,
      { content_type: :json, Authorization: "Bearer #{token}" }
    )
    
    JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Error initiating payment: #{e.response}")
    { error: 'Failed to initiate payment' }
    
    end



end 

end






