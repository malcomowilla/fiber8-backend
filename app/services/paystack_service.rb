# app/services/paystack_service.rb
require 'net/http'
require 'json'

class PaystackService
  BASE_URL = 'https://api.paystack.co'

  # Paystack's equivalent of "STK push" — POST /charge with a mobile_money
  # payload. Paystack pushes the prompt to the phone itself; we get back a
  # reference + status ('pay_offline' == prompt sent, check phone).
  def self.initiate_mobile_money_charge(setting, amount:, phone:, email:, reference:, metadata: {})
  formatted_phone = normalize_phone(phone)      # "+254722000000"
  digits_only = formatted_phone.delete('+')      # "254722000000"

  body = {
    amount: (amount.to_f * 100).to_i,
    email: email.presence || "#{digits_only}@hotspot.customer",
    currency: 'KES',
    reference: reference,
    mobile_money: { phone: formatted_phone, provider: 'mpesa' },
    metadata: metadata
  }

  response = post('/charge', setting.secret_key, body)

  if response['status'] == true
    data = response['data'] || {}
    {
      success: true,
      reference: data['reference'] || reference,
      status: data['status'],
      display_text: data['display_text'],
      raw: data
    }
  else
    { success: false, error: response['message'] || 'Failed to initiate Paystack charge' }
  end
rescue => e
  { success: false, error: e.message }
end
  # Paystack's own recommended polling endpoint for offline/mobile-money
  # charges. Only used as a manual "check now" fallback — the webhook is
  # the primary source of truth (see PaystackCallbacksController).
  def self.check_charge_status(setting, reference)
    response = get("/charge/#{reference}", setting.secret_key)
    if response['status'] == true
      data = response['data'] || {}
      { success: true, status: data['status'], raw: data }
    else
      { success: false, error: response['message'] || 'Could not fetch charge status' }
    end
  rescue => e
    { success: false, error: e.message }
  end

  def self.test_connection(setting)
    response = get('/transaction?perPage=1', setting.secret_key)
    response['status'] == true
  rescue
    false
  end


def self.normalize_phone(phone)
  digits = phone.to_s.gsub(/\D/, '')
  local_digits =
    if digits.start_with?('254')
      digits[3..]
    elsif digits.start_with?('0')
      digits[1..]
    else
      digits
    end
  "+254#{local_digits}"
end



  def self.post(path, secret_key, body)
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{secret_key}")
    req.body = body.to_json
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 15) { |http| http.request(req) }
    JSON.parse(res.body)
  end

  def self.get(path, secret_key)
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Get.new(uri, 'Authorization' => "Bearer #{secret_key}")
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 15) { |http| http.request(req) }
    JSON.parse(res.body)
  end
end