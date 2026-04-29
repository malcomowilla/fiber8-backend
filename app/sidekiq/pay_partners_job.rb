# app/jobs/pay_partners_job.rb
class PayPartnersJob
  include Sidekiq::Job
  queue_as :default

  def perform
    Rails.logger.info "Starting Partner Payout Job..."

   
       Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do

 Partner.where(status: "active", account_id: tenant.id).find_each do |partner|
      next unless tenant
process_partner(partner)

      end
    end
   
    end
  end

  private

  # --------------------------
  # 💰 PROCESS EACH PARTNER
  # --------------------------
  def process_partner(partner)
    # ❌ Skip manual payouts
    if partner.payout_method == "manual"
      Rails.logger.info "Skipping partner #{partner.id} (manual payout)"
      return
    end

    # ❌ Ensure mpesa number exists
    if partner.mpesa_number.blank? || partner.phone.blank?
      Rails.logger.info "Skipping partner #{partner.id} (no mpesa number)"
      return
    end

    # 📊 Fetch revenues (use separate flag to avoid conflict)
    revenues = PpPoeMpesaRevenue
      .where(account_id: partner.account_id, partner_paid_out: false)
      .where("created_at <= ?", 4.minutes.ago)

    if revenues.empty?
      Rails.logger.info "No revenues for partner #{partner.id}"
      return
    end

    total_revenue = revenues.sum(:amount)

    # 💰 Calculate payout amount
    amount = calculate_commission(partner, total_revenue)

    # ❌ Skip invalid amounts
    if amount <= 0
      Rails.logger.info "Skipping partner #{partner.id} (amount <= 0)"
      return
    end

    # ❌ Respect minimum payout
    if amount < partner.minimum_payout.to_i
      Rails.logger.info "Skipping partner #{partner.id} (below minimum payout)"
      return
    end

    Rails.logger.info "Partner #{partner.id} payout amount: #{amount}"

    # 🚀 Send B2C payment
    success = send_b2c(partner.mpesa_number, amount.to_i, ActsAsTenant.current_tenant)

    if success
      revenues.update_all(
        partner_paid_out: true,
        partner_paid_out_at: Time.current,
        partner_amount_disbursed: amount.to_i
      )

      create_payout_record(partner, amount)

      Rails.logger.info "✅ Partner #{partner.id} paid successfully"
    else
      Rails.logger.info "❌ Partner #{partner.id} payout failed"
    end
  end

  # --------------------------
  # 📊 COMMISSION LOGIC
  # --------------------------
  def calculate_commission(partner, total_revenue)
    case partner.commission_type
    when "fixed"
      partner.fixed_amount.to_i
    when "percentage"
      (total_revenue * (partner.commission_rate.to_f / 100)).round
    else
      0
    end
  end

  # --------------------------
  # 🧾 TRACK PAYOUT
  # --------------------------
  def create_payout_record(partner, amount)
    PartnerPayout.create!(
      partner_id: partner.id,
      account_id: partner.account_id,
      amount: amount,
      status: "success",
      paid_at: Time.current,
      payout_method: "mpesa"
    )
  rescue => e
    Rails.logger.error "Failed to create payout record: #{e.message}"
  end

  # --------------------------
  # 🔁 B2C PAYMENT
  # --------------------------
  def send_b2c(phone_number, amount, tenant)
    token = fetch_access_token
    mpesa_setting = tenant.hotspot_mpesa_setting
    return false unless token

    payload = {
      OriginatorConversationID: SecureRandom.hex(10),
      InitiatorName: ENV['API_INITIATOR_USERNAME'],
      SecurityCredential: ENV['B2C_API_INITIATOR_PASSWORD'],
      CommandID: "BusinessPayment",
      Amount: amount,
      PartyA: mpesa_setting.short_code || ENV['B2C_SHORTCODE'],
      PartyB: format_phone(phone_number),
      Remarks: "Partner payout",
      QueueTimeOutURL: "https://#{tenant.subdomain}.#{ENV['HOST']}/b2c_timeout",
      ResultURL: "https://#{tenant.subdomain}.#{ENV['HOST']}/b2c_result",
      Occassion: "PartnerCommission"
    }

    begin
      response = RestClient.post(
        "https://api.safaricom.co.ke/mpesa/b2c/v1/paymentrequest",
        payload.to_json,
        { content_type: :json, Authorization: "Bearer #{token}" }
      )

      parsed = JSON.parse(response.body)

      if parsed["ResponseCode"] == "0" || parsed["ResultCode"] == "0"
        Rails.logger.info "B2C success: #{response.body}"
        true
      else
        Rails.logger.info "B2C API error: #{parsed}"
        false
      end
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.info "B2C exception: #{e.response.body}"
      false
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
    Rails.logger.info "Token error: #{e.response}"
    nil
  end

  # --------------------------
  # 📞 FORMAT PHONE
  # --------------------------
  def format_phone(phone)
    phone.gsub(/^0/, '254')
  end
end