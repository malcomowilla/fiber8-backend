

class DisbursePaymentController < ApplicationController
  
before_action :set_tenant
  before_action :set_time_zone




  def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end








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



  def disburse_funds
    token = fetch_access_token
    Rails.logger.info "Mpesa token: #{token}"
    return render json: { error: "Unable to generate access token" }, status: :unprocessable_entity unless token
    # mpesa = ActsAsTenant.current_tenant.hotspot_mpesa_setting.find_by(account_type: "Paybill")
    mpesa = HotspotMpesaSetting.find_by(account_type: "Paybill")
    
    return render json: { error: "M-Pesa Settings Not Found" }, status: :not_found unless mpesa
 host = request.headers['X-Subdomain']
    payload = {
      
    OriginatorConversationID: "600997_Test_32et3241ed8yu", 
    InitiatorName: mpesa.api_initiator_username,
    SecurityCredential: mpesa.api_initiator_password,
    CommandID: "BusinessPayment", 
    Amount: params[:amount], 
    PartyA: mpesa.short_code, 
    PartyB: params[:phone_number],
    Remarks: "remarked", 
    QueueTimeOutURL: "https://#{host}.#{ENV['HOST']}/disburse_funds_results_timeout", 
    ResultURL: "https://#{host}.#{ENV['HOST']}/disburse_funds_results", 
    Occassion: "PartnerPayment"
    }

    begin
      response = RestClient.post(
          "https://api.safaricom.co.ke/mpesa/b2c/v1/paymentrequest",

        payload.to_json,
        { content_type: :json, Authorization: "Bearer #{token}" }
      )

      render json: JSON.parse(response.body), status: :ok

    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.info("Error disbursing funds: #{e.response.body}")
      # render json: { error: "Failed to register callback URLs" }, status: :bad_request
    render json: { error: "#{e.response.body}" }, status: :bad_request

    end
  end





private


def fetch_access_token
    mpesa = HotspotMpesaSetting.find_by(account_type: "Paybill")
#  mpesa = ActsAsTenant.current_tenant.hotspot_mpesa_setting.find_by(account_type: "Paybill")

    return nil unless mpesa

    consumer_key     = mpesa.consumer_key
    consumer_secret  = mpesa.consumer_secret

    api_url = "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"

    response = RestClient.get(api_url, {
      Authorization: "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}"
    })

    JSON.parse(response.body)["access_token"]
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info("Error fetching access token: #{e.response}")
    nil
  end






end