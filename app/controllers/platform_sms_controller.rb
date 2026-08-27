class PlatformSmsController < ApplicationController
  # gate with whatever before_action your other system-admin-only
  # endpoints use (e.g. authenticate_system_admin!) — not set_tenant,
  # this has no X-Subdomain, it's your own account, not a tenant's.

  def balance
    setting = PlatformBulkSmsSetting.current
    uri = URI("https://sms.textsms.co.ke/api/services/getbalance/apikey=#{setting.api_key}/partnerID=#{setting.partner_id}")
    response = Net::HTTP.get_response(uri)
    data = JSON.parse(response.body) rescue {}
    render json: { balance: data['balance'] || data['credit'] || 'N/A' }
  rescue => e
    render json: { error: e.message }, status: :service_unavailable
  end
end