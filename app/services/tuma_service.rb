# app/services/tuma_service.rb
class TumaService
  BASE_URL = "https://api.tuma.co.ke"

  class << self
    def fetch_token(setting)
      return setting.cached_token if setting.token_valid?

      uri = URI("#{BASE_URL}/auth/token")
      res = Net::HTTP.post(uri, {
        email: setting.business_email,
        api_key: setting.api_key
      }.to_json, "Content-Type" => "application/json")

      data = JSON.parse(res.body) rescue {}
      raise "Tuma auth failed: #{data['message'] || res.body}" unless data["success"]

      setting.update!(
        cached_token: data["token"],
        token_expires_at: Time.current + (data["expires_in"] || 86_400).seconds
      )

      data["token"]
    end

    def initiate_stk_push(setting, amount:, phone:, callback_url:, description:)
      token = fetch_token(setting)

      uri = URI("#{BASE_URL}/payment/stk-push")
      req = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
      req["Authorization"] = "Bearer #{token}"
      req.body = {
        amount: amount,
        phone: normalize_phone(phone),
        callback_url: callback_url,
        description: description
      }.to_json

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      data = JSON.parse(res.body) rescue {}

      data["success"] ? { success: true, response: data["data"] }
                       : { success: false, error: data["message"] || "Tuma STK push failed" }
    rescue => e
      { success: false, error: e.message }
    end

    private

    def normalize_phone(phone)
      digits = phone.to_s.gsub(/\D/, '')
      return digits if digits.start_with?('254')
      return "254#{digits[1..]}" if digits.start_with?('0')
      digits
    end
  end
end