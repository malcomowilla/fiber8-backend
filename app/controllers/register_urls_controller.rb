class RegisterUrlsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity
  before_action :set_time_zone

   
  
  
   def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end

  def update_last_activity
    current_user&.update!(last_activity_active: Time.current)
  end

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def register_url
    token = fetch_access_token
    return render json: { error: "Unable to generate access token" }, status: :unprocessable_entity unless token

    mpesa = HotspotMpesaSetting.find_by(account_type: "Paybill")
    return render json: { error: "M-Pesa Settings Not Found" }, status: :not_found unless mpesa
 host = request.headers['X-Subdomain']
    payload = {
      ShortCode: mpesa.short_code,
      ResponseType: "Completed",
      ConfirmationURL: "https://#{host}.#{ENV['HOST']}/#{ENV['CONFIRMATION_URL']}",
      ValidationURL: "https://#{host}.#{ENV['HOST']}/#{ENV['VALIDATION_URL']}",
      # OR replace with static hosted domain if not tenant-based
    }

    begin
      response = RestClient.post(
          "https://api.safaricom.co.ke/mpesa/c2b/v2/registerurl",
        payload.to_json,
        { content_type: :json, Authorization: "Bearer #{token}" }
      )

      render json: JSON.parse(response.body), status: :ok

    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Error registering M-Pesa URLs: #{e.response.body}")
      # render json: { error: "Failed to register callback URLs" }, status: :bad_request
    render json: { error: "#{e.response.body}" }, status: :bad_request

    end
  end

  private

  def fetch_access_token
    mpesa = HotspotMpesaSetting.find_by(account_type: "Paybill")
    return nil unless mpesa

    consumer_key     = mpesa.consumer_key
    consumer_secret  = mpesa.consumer_secret

    api_url = "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"

    response = RestClient.get(api_url, {
      Authorization: "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}"
    })

    JSON.parse(response.body)["access_token"]
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("Error fetching access token: #{e.response}")
    nil
  end

  
end



