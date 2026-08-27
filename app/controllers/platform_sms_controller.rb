class PlatformSmsController < ApplicationController
  # gate with whatever before_action your other system-admin-only
  # endpoints use (e.g. authenticate_system_admin!) — not set_tenant,
  # this has no X-Subdomain, it's your own account, not a tenant's.

  def balance
    uri = URI("https://sms.textsms.co.ke/api/services/getbalance")
    uri.query = URI.encode_www_form(
      apikey: ENV['TEXT_SMS_API_KEY'],
      partnerID: ENV['TEXTSMS_PARTNER_ID']
    )

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 5  # time to establish connection
    http.read_timeout = 8  # time waiting for TextSMS to respond

    response = http.get(uri.request_uri)

    if response.is_a?(Net::HTTPSuccess)
      balance_data = JSON.parse(response.body)
      render json: { balance: balance_data['credit'] }, status: :ok
    else
      Rails.logger.info "PlatformSmsController#balance: HTTP #{response.code} - #{response.body}"
      render json: { error: "Error getting balance: #{response.body}" }, status: :service_unavailable
    end

  rescue Net::OpenTimeout, Net::ReadTimeout
    Rails.logger.info "PlatformSmsController#balance: TextSMS request timed out"
    render json: { error: 'SMS provider timed out' }, status: :service_unavailable
  rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
    Rails.logger.info "PlatformSmsController#balance: unreachable (#{e.class}: #{e.message})"
    render json: { error: 'SMS provider unreachable' }, status: :service_unavailable
  rescue JSON::ParserError => e
    Rails.logger.info "PlatformSmsController#balance: bad response body: #{e.message}"
    render json: { error: 'Unexpected response from SMS provider' }, status: :service_unavailable
  rescue => e
    Rails.logger.info "PlatformSmsController#balance: #{e.class}: #{e.message}"
    render json: { error: e.message }, status: :service_unavailable
  end
end