def balance
  uri = URI("https://sms.textsms.co.ke/api/services/getbalance/")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 5
  http.read_timeout = 8

  request = Net::HTTP::Post.new(uri.request_uri)
  request["Content-Type"] = "application/json"
  request["Accept"] = "application/json"

  request.body = {
    apikey: ENV["TEXT_SMS_API_KEY"],
    partnerID: ENV["TEXTSMS_PARTNER_ID"]
  }.to_json

  response = http.request(request)

  Rails.logger.info "TextSMS balance response: #{response.code} #{response.body}"

  if response.is_a?(Net::HTTPSuccess)
    balance_data = JSON.parse(response.body)

    render json: {
      balance: balance_data["credit"] || balance_data
    }, status: :ok
  else
    Rails.logger.error(
      "PlatformSmsController#balance: HTTP #{response.code} - #{response.body}"
    )

    render json: {
      error: "Error getting balance: #{response.body}"
    }, status: :service_unavailable
  end

rescue Net::OpenTimeout, Net::ReadTimeout
  Rails.logger.error "PlatformSmsController#balance: TextSMS request timed out"

  render json: {
    error: "SMS provider timed out"
  }, status: :service_unavailable

rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
  Rails.logger.error(
    "PlatformSmsController#balance: unreachable (#{e.class}: #{e.message})"
  )

  render json: {
    error: "SMS provider unreachable"
  }, status: :service_unavailable

rescue JSON::ParserError => e
  Rails.logger.error(
    "PlatformSmsController#balance: bad response body: #{e.message}"
  )

  render json: {
    error: "Unexpected response from SMS provider"
  }, status: :service_unavailable

rescue => e
  Rails.logger.error(
    "PlatformSmsController#balance: #{e.class}: #{e.message}"
  )

  render json: {
    error: e.message
  }, status: :service_unavailable
end