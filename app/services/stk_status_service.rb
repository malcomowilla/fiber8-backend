class StkStatusService

  class << self



    def initiate_stk_query(shortcode,passkey,consumer_key,consumer_secret,
      checkout_request_id
       ) 
    api_url = 'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'

    
    
    
    
     token = fetch_access_token(api_url, consumer_key, consumer_secret)
     
    if token
      response = stk_push_query(token,shortcode,passkey,checkout_request_id
      )
      { success: true, response: response }
    else
      { success: false, error: 'Failed to fetch access token' }
    end
  rescue => e
    Rails.logger.error("StkStatusService Error: #{e.message}")
    { success: false, error: e.message }
  end



    private

    def fetch_access_token(api_url, consumer_key, consumer_secret)
      
      response = RestClient.get(api_url, { params: { grant_type: 'client_credentials' }, Authorization: "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}" })
    
      body = response.body
      Rails.logger.info("OAuth Response Body: #{body}")
      access_token = JSON.parse(response.body)['access_token']
    
    access_token
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Error fetching access token: #{e.response}")
      nil
    end
    
    def stk_push_query(token,shortcode,passkey,checkout_request_id
       )
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    
      password = Base64.strict_encode64("#{shortcode}#{passkey}#{timestamp}")
    
    
      Rails.logger.info("StkPush Request Timestamp: #{timestamp}")
      Rails.logger.info("StkPush Request Password: #{password}")
    

      
    payload = {    
      BusinessShortCode: shortcode,    
      Password:  password,    
      Timestamp:timestamp,  
      CheckoutRequestID: checkout_request_id,  
        
      
    }
    

    Rails.logger.info("StkPush Request Payload: #{payload}")
    
    response = RestClient.post(
      'https://api.safaricom.co.ke/mpesa/stkpushquery/v1/query',
      payload.to_json,
      { content_type: :json, Authorization: "Bearer #{token}" }
    )
    
    
     body = response.body
      Rails.logger.info("StkQuery status Request Response: #{body}")
      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Error initiating stk query: #{e.response}")
    { error: 'Failed to initiate stk query' }
    
    end



end 

end






