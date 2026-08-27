class PlatformSmsController < ApplicationController
  # gate with whatever before_action your other system-admin-only
  # endpoints use (e.g. authenticate_system_admin!) — not set_tenant,
  # this has no X-Subdomain, it's your own account, not a tenant's.

  def balance
    setting = PlatformBulkSmsSetting.current

    uri = URI("https://sms.textsms.co.ke/api/services/getbalance")
    params = {
      apikey: ENV['TEXT_SMS_API_KEY'],
      partnerID: ENV['TEXTSMS_PARTNER_ID']
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      balance_data = JSON.parse(response.body)
      render json: { balance: balance_data['credit'] }, status: :ok
    else
      render json: { error: "Error getting balance: #{response.body}" }, status: :service_unavailable
    end
  rescue => e
    render json: { error: e.message }, status: :service_unavailable
  end
end