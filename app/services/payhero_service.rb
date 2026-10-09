require 'net/http'
require 'json'

class PayheroService
  BASE_URL = 'https://backend.payhero.co.ke/api/v2'.freeze
  DEFAULT_CALLBACK_URL = 'https://owitech.co.ke/paystack_owitech_callback'.freeze

  class << self
    # Registers a paybill / till / bank channel inside the platform's PayHero account.
    def register_channel(channel_type:, short_code:, account_number:, description:)
      call(:post, '/payment_channels', body: {
        channel_type:   channel_type,
        account_id:     ENV['PAYHERO_ACCOUNT_ID'].to_i,
        short_code:     short_code.to_i,
        account_number: account_number.to_s,
        description:    description
      })
    end

    def initiate_stk_push(amount:, phone:, channel_id:, external_reference:, customer_name: nil, callback_url: nil)
      call(:post, '/payments', body: {
        amount:             amount.to_i,
        phone_number:       phone.to_s,
        channel_id:         channel_id.to_i,
        provider:           'm-pesa',
        external_reference: external_reference,
        customer_name:      customer_name,
        callback_url:       callback_url || ENV['PAYHERO_CALLBACK_URL'].presence || DEFAULT_CALLBACK_URL
      }.compact)
    end

    # reference can be PayHero's reference or the M-Pesa receipt code
    def transaction_status(reference)
      call(:get, '/transaction-status', query: { reference: reference })
    end

    private

    # PAYHERO_BEARER_TOKEN may hold the raw token or the full "Basic xxx" / "Bearer xxx" value.
    def auth_header
      token = ENV['PAYHERO_BEARER_TOKEN'].to_s.strip
      return nil if token.empty?
      token.start_with?('Basic ', 'Bearer ') ? token : "Basic #{token}"
    end

    def call(method, path, body: nil, query: nil)
      header = auth_header
      return { success: false, error: 'PAYHERO_BEARER_TOKEN is not set' } unless header

      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(query) if query

      req = method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
      req['Authorization'] = header
      req['Content-Type']  = 'application/json'
      req.body = body.to_json if body

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 8, read_timeout: 20) do |http|
        http.request(req)
      end

      parsed = JSON.parse(res.body) rescue {}
      ok = res.is_a?(Net::HTTPSuccess) && parsed['success'] != false

      if ok
        { success: true, response: parsed }
      else
        { success: false, response: parsed,
          error: parsed['error_message'] || parsed['message'] || parsed['error'] || "PayHero returned #{res.code}" }
      end
    rescue Net::OpenTimeout, Net::ReadTimeout
      { success: false, error: 'PayHero timed out, please try again' }
    rescue StandardError => e
      Rails.logger.error "PayheroService error: #{e.class} #{e.message}"
      { success: false, error: 'Could not reach PayHero' }
    end
  end
end