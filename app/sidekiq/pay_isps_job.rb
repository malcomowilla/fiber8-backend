class PayIspsJob
  include Sidekiq::Job
  queue_as :default

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        process_tenant_payout(tenant)
      end
    end
  end

  private

  def process_tenant_payout(tenant)
    mpesa_setting = tenant.hotspot_mpesa_setting
    return unless mpesa_setting.present?

    phone_number = mpesa_setting.phone_number
    return if phone_number.blank?

    # ✅ Get unpaid revenues older than 4 minutes
    revenues = HotspotMpesaRevenue
      .where(account_id: tenant.id, paid_out: false)
      .where("created_at <= ?", 4.minutes.ago)

    return if revenues.empty?

    total_amount = revenues.sum(:amount)
    return if total_amount <= 0 || total_amount < 10

    # ✅ Fees
    # transaction_cost = total_amount * 0.01
    transaction_cost = (total_amount * 0.01).round

    plan = tenant.hotspot_and_dial_plan
    is_trial = plan&.name == "Free Trial"

    platform_fee = is_trial ? 0 : total_amount * 0.04

    net_amount = total_amount - transaction_cost - platform_fee
    # net_amount = total_amount - transaction_cost
    return if net_amount <= 0

    Rails.logger.info "Tenant #{tenant.id} total: #{total_amount}, net: #{net_amount}"

    # ✅ Mark as paid BEFORE sending (prevents double payout)
    # batch_id = SecureRandom.uuid

    revenues.update_all(
      paid_out: true,
      paid_out_at: Time.current,
      # payout_batch_id: batch_id
    )

    # ✅ Send money
    send_b2c(phone_number, net_amount.to_i, tenant)
  end

  # --------------------------
  # 🔁 B2C PAYMENT
  # --------------------------
  def send_b2c(phone_number, amount, tenant)
    token = fetch_access_token
    return unless token

    payload = {
      OriginatorConversationID: SecureRandom.hex(10),
      InitiatorName: ENV['API_INITIATOR_USERNAME'],
      SecurityCredential: ENV['B2C_API_INITIATOR_PASSWORD'],
      CommandID: "BusinessPayment",
      Amount: amount,
      PartyA: ENV['B2C_SHORTCODE'],
      PartyB: format_phone(phone_number),
      Remarks: "ISP payout",
      QueueTimeOutURL: "#{callback_base_url(tenant)}/b2c_timeout",
      ResultURL: "#{callback_base_url(tenant)}/b2c_result",
      Occassion: "ISPSettlement"
    }

    begin
      response = RestClient.post(
        "https://api.safaricom.co.ke/mpesa/b2c/v1/paymentrequest",
        payload.to_json,
        { content_type: :json, Authorization: "Bearer #{token}" }
      )

      Rails.logger.info "B2C success: #{response.body}"

    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "B2C error: #{e.response.body}"
    end
  end

  # --------------------------
  # 🔐 ACCESS TOKEN
  # --------------------------
  def fetch_access_token
    consumer_key = ENV['CONSUMER_KEY']
    consumer_secret = ENV['CONSUMER_SECRET']

    response = RestClient.get(
      "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      Authorization: "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}"
    )

    JSON.parse(response.body)["access_token"]

  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Token error: #{e.response}"
    nil
  end

  # --------------------------
  # 📞 FORMAT PHONE
  # --------------------------
  def format_phone(phone)
    phone.gsub(/^0/, '254')
  end

  # --------------------------
  # 🌐 CALLBACK URL
  # --------------------------
  def callback_base_url(tenant)
    "https://#{tenant.subdomain}.#{ENV['HOST']}"
  end
end