# app/services/tuma_service.rb

class TumaService
  BASE_URL = "https://api.tuma.co.ke"

  class << self
    def fetch_token(setting)
      return setting.cached_token if setting.token_valid?

      uri = URI("#{BASE_URL}/auth/token")
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = true

      req = Net::HTTP::Post.new(uri.path)
      req["Content-Type"] = "application/json"  # ✅ JSON format
      req.body = {
        email: setting.business_email,
        api_key: setting.api_key
      }.to_json

      res = http.request(req)
      data = JSON.parse(res.body) rescue {}

      Rails.logger.info "Tuma Token Response: #{res.code} - #{data.inspect}"

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
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = true
      
      req = Net::HTTP::Post.new(uri.path)
      req["Authorization"] = "Bearer #{token}"
      req["Content-Type"] = "application/json"
      req.body = {
        amount: amount.to_f,
        phone: normalize_phone(phone),
        callback_url: callback_url,
        description: description
      }.to_json

      res = http.request(req)
      data = JSON.parse(res.body) rescue {}

      Rails.logger.info "Tuma STK Push Response: #{res.code} - #{data.inspect}"

      if data["success"]
        { success: true, response: data["data"] }
      else
        { success: false, error: data["message"] || "Tuma STK push failed", status_code: res.code }
      end
    rescue => e
      Rails.logger.error "Tuma STK Push Error: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def normalize_phone(phone)
      digits = phone.to_s.gsub(/\D/, '')
      return digits if digits.start_with?('254')
      return "254#{digits[1..]}" if digits.start_with?('0')
      "254#{digits}"
    end
  end
end