class PlatformBulkSmsBalanceService
  CACHE_TTL = 60.seconds

  def self.available_balance
    Rails.cache.fetch('platform_bulk_sms_live_balance', expires_in: CACHE_TTL) do
      fetch_live_balance
    end
  end

  def self.sellable_headroom
    live = available_balance
    return nil if live.nil?

    outstanding = TenantSmsWallet.sum(:balance)
    live - outstanding
  end













  

  def self.fetch_live_balance
    uri = URI("https://sms.textsms.co.ke/api/services/getbalance")
    uri.query = URI.encode_www_form(
      apikey: ENV['TEXT_SMS_API_KEY'],
      partnerID: ENV['TEXTSMS_PARTNER_ID']
    )

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 5
    http.read_timeout = 8

    response = http.get(uri.request_uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)['credit'].to_i
  rescue Net::OpenTimeout, Net::ReadTimeout
    Rails.logger.error "PlatformBulkSmsBalanceService: TextSMS request timed out"
    nil
  rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
    Rails.logger.error "PlatformBulkSmsBalanceService: unreachable (#{e.class}: #{e.message})"
    nil
  rescue => e
    Rails.logger.error "PlatformBulkSmsBalanceService: failed to fetch balance: #{e.message}"
    nil
  end
end