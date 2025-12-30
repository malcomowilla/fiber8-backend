

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