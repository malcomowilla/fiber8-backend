class WithdrawWalletController < ApplicationController

  set_current_tenant_through_filter

  before_action :set_tenant








def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
     ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
  # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
  end




  private

  def send_b2c(phone_number, amount, tenant)
    token = fetch_access_token(tenant)
        mpesa_setting = tenant.hotspot_mpesa_setting

    return unless token


    payload = {
       OriginatorConversationID: "600997_Test_32et3241ed8yu",
       InitiatorName: mpesa_setting.api_initiator_username || ENV['API_INITIATOR_USERNAME'],
      SecurityCredential: mpesa_setting.api_initiator_password || ENV['B2C_API_INITIATOR_PASSWORD'],
      CommandID: "BusinessPayment",
      Amount: amount,
      PartyA: mpesa_setting.short_code || ENV['B2C_SHORTCODE'],
      PartyB: format_phone(phone_number),
      Remarks: "ok",
      QueueTimeOutURL: "https://#{tenant.subdomain}.#{ENV['HOST']}/disburse_funds_results_timeout",
      ResultURL: "https://#{tenant.subdomain}.#{ENV['HOST']}/disburse_funds_result",
      Occassion: "ISPSettlement"
    }
 begin
    response = RestClient.post(
      "https://api.safaricom.co.ke/mpesa/b2c/v1/paymentrequest",
      payload.to_json,
      { content_type: :json, Authorization: "Bearer #{token}" }
    )
    parsed = JSON.parse(response.body)
    # Safaricom returns ResultCode == "0" on success
    if parsed["ResultCode"] == "0" || parsed["ResponseCode"] == "0"
      Rails.logger.info "B2C success: #{response.body}"
      return true
    else
      Rails.logger.info "B2C API returned error: #{parsed}"
      return false
    end
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "B2C exception: #{e.response.body}"
    return false
  end
  end



  
  # --------------------------
  # 🔐 ACCESS TOKEN
  # --------------------------
  def fetch_access_token(tenant)
    mpesa_setting = tenant.hotspot_mpesa_setting

  
    consumer_key =   mpesa_setting.consumer_key || ENV['CONSUMER_KEY']
    consumer_secret = mpesa_setting .consumer_secret || ENV['CONSUMER_SECRET']

    response = RestClient.get(
      "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      Authorization: "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}"
    )

    JSON.parse(response.body)["access_token"]
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "Token error: #{e.response}"
    nil
  end

  # --------------------------
  # 📞 FORMAT PHONE
  # --------------------------
  def format_phone(phone)
    phone.gsub(/^0/, '254')
  end




end