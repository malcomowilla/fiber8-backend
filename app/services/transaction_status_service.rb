class TransactionStatusService

  class << self



    def initiate_transaction_status_query(shortcode,passkey,consumer_key,
      consumer_secret,transaction_id,initiator,security_credentials,host
       
       ) 
    api_url = 'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'

    
    
    
    
     token = fetch_access_token(api_url, consumer_key, consumer_secret)
     
    if token
      response = transaction_status_query(
        token,shortcode,initiator,
      transaction_id, security_credentials,host
      )
      { success: true, response: response }
    else
      { success: false, error: 'Failed to fetch access token' }
    end
  rescue => e
    Rails.logger.info("Transaction StatusService Error: #{e.message}")
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
      Rails.logger.info("Error fetching access token: #{e.response}")
      nil
    end
    
    def transaction_status_query(token,shortcode,initiator,
      transaction_id, security_credentials,host
    
      
       )
    
      # Rails.logger.info("StkPush Request Timestamp: #{timestamp}")
      # Rails.logger.info("StkPush Request Password: #{password}")
    

      
    payload = {    
      Initiator: initiator,
      SecurityCredential: security_credentials,
      CommandID: "TransactionStatusQuery",
      TransactionID: transaction_id,
      OriginalConversationID: transaction_id,
      PartyA: shortcode,   
      IdentifierType: 4,
      ResultURL: "https://#{host}.#{ENV['HOST2']}/mpesa_transactionstatus_result",
      QueueTimeOutURL: "https://#{host}.#{ENV['HOST2']}/mpesa_transactionstatus_timeout",
      
      Remarks: 'status check',
      Occasion: 'Hotspot',
     
        
      
    }
    

    Rails.logger.info("TRansaction Status Request Payload: #{payload}")
    
    response = RestClient.post(
      'https://api.safaricom.co.ke/mpesa/transactionstatus/v1/query',
      payload.to_json,
      { content_type: :json, Authorization: "Bearer #{token}" }
    )
    
    
     body = response.body
      Rails.logger.info("Transaction Status Request Response: #{body}")
      JSON.parse(response.body)
    rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info("Error initiating transaction status query: #{e.response}")
    { error: 'Failed to initiate transaction status query' }
    
    end



end 

end






