class PayIspsJob
  include Sidekiq::Job
  queue_as :default

  PLATFORM_FEE_PERCENT = 0.04

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        # Pay out tenants without API keys
        if tenant.hotspot_mpesa_setting&.no_api_keys
          process_tenant_payout(tenant)
        end
#          setting = tenant.hotspot_mpesa_setting
#     next if setting.nil?  
#     next unless setting.no_api_keys == true  
#      # or next if setting.no_api_keys == false                   # skip tenants with no settings
# process_tenant_payout(tenant)
        # Generate platform fee invoice for everyone (once per 30 days)
        process_platform_fee_invoice(tenant)
      end
    end
  end

  private

  # --------------------------
  # 💵 PAY ISP Payout (only for tenants without API keys)
  # --------------------------
  def process_tenant_payout(tenant)
    mpesa_setting = tenant.hotspot_mpesa_setting
    return unless mpesa_setting&.phone_number.present?

    revenues = PpPoeMpesaRevenue
      .where(account_id: 202, paid_out: false)
      .where("created_at <= ?", 4.minutes.ago)

    return if revenues.empty?

    total_amount = revenues.sum(:amount)
    return if total_amount <= 0 || total_amount < 10

    # transaction_cost = (total_amount * 0.01).round
transaction_cost = (total_amount * 0.01).ceil
    plan = tenant.hotspot_and_dial_plan
    # platform_fee = plan&.name == "Free Trial" ? 0 : (total_amount * PLATFORM_FEE_PERCENT).round

    # net_amount = total_amount - transaction_cost - platform_fee
        net_amount = total_amount - transaction_cost

    return if net_amount <= 0
     return if net_amount < 10 

    Rails.logger.info "Tenant #{tenant.id} total: #{total_amount}, net: #{net_amount}"

    # Mark revenues as paid
    # revenues.update_all(paid_out: true, paid_out_at: Time.current)
# Rails.logger.info "Phone number (formatted): #{format_phone(mpesa_setting.phone_number)}"

    # Send B2C payout
    success = send_b2c(mpesa_setting.phone_number, net_amount.to_i, tenant)
     if success
    revenues.update_all(paid_out: true, paid_out_at: Time.current, amount_disbursed: net_amount.to_i)
    Rails.logger.info "B2C succeeded and revenues marked paid for tenant #{tenant.id}"
  else
    Rails.logger.info "B2C failed for tenant #{tenant.id} – revenues NOT marked paid, will retry later"
    # Optionally: raise error to trigger Sidekiq retry
    # raise "B2C payment failed for tenant #{tenant.id}"
  end

  end




  # --------------------------
  # 📄 GENERATE PLATFORM FEE INVOICE (once per 30 days)
  # --------------------------
  def process_platform_fee_invoice(tenant)
    # Skip if tenant has no hotspot plan or is on Free Trial
    plan = tenant.hotspot_and_dial_plan
    return unless plan&.present?
    return if plan.name == "Free Trial"

    # Check last platform fee invoice
    last_invoice = tenant.invoices
                         .where(plan_name: "Platform Fee (4% Hotspot)")
                         .order(created_at: :desc)
                         .first
    if last_invoice&.last_invoiced_at.present? && last_invoice.last_invoiced_at > 30.days.ago
      Rails.logger.info "Skipping platform fee invoice for tenant #{tenant.id} — already invoiced"
      return
    end

    # Calculate total hotspot revenue for the month
    hotspot_total = PpPoeMpesaRevenue
                      .where(account_id: tenant.id)
                      .where(created_at: 1.month.ago.beginning_of_month..1.month.ago.end_of_month)
                      .sum(:amount)
    platform_fee = (hotspot_total * PLATFORM_FEE_PERCENT).round
    return if platform_fee <= 0

    # Create invoice
    invoice = Invoice.create!(
      account_id: tenant.id,
      invoice_number: generate_invoice_number,
      plan_name: "Platform Fee (4% Hotspot)",
      invoice_date: Time.current,
      due_date: Time.current + 5.days,
      invoice_desciption: {
        summary: "Platform fee deduction",
        details: "4% of hotspot revenue collected by the platform",
        amount: platform_fee,
        currency: "KES"
      }.to_json,
      total: platform_fee,
      status: "unpaid",
      last_invoiced_at: Time.current
    )

    # Send SMS notification
    send_platform_fee_sms(
      tenant.users.where(role: "super_administrator").first.phone_number,
      invoice.due_date,
      invoice.invoice_number,
      tenant.users.where(role: "super_administrator").first.username,
      invoice.plan_name,
      platform_fee
    )
  end

  # --------------------------
  # 🔁 B2C PAYMENT
  # --------------------------
  def send_b2c(phone_number, amount, tenant)
    token = fetch_access_token
    return unless token


    payload = {
       OriginatorConversationID: "600997_Test_32et3241ed8yu",
      InitiatorName: ENV['API_INITIATOR_USERNAME'],
      SecurityCredential: ENV['B2C_API_INITIATOR_PASSWORD'],
      CommandID: "BusinessPayment",
      Amount: amount,
      PartyA: ENV['B2C_SHORTCODE'],
      PartyB: format_phone(phone_number),
      Remarks: "ok",
      QueueTimeOutURL: "https://#{tenant.subdomain}.#{ENV['HOST']}/disburse_funds_results_timeout",
      ResultURL: "https://#{tenant.subdomain}.#{ENV['HOST']}/disburse_funds_result",
      Occassion: "ISPSettlement"
    }
 begin
    response = RestClient.post(
      "https://api.safaricom.co.ke/mpesa/b2c/v1/paymentrequest",
      payload.to_json,
      { content_type: :json, Authorization: "Bearer #{token}" }
    )
    parsed = JSON.parse(response.body)
    # Safaricom returns ResultCode == "0" on success
    if parsed["ResultCode"] == "0" || parsed["ResponseCode"] == "0"
      Rails.logger.info "B2C success: #{response.body}"
      return true
    else
      Rails.logger.info "B2C API returned error: #{parsed}"
      return false
    end
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "B2C exception: #{e.response.body}"
    return false
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

  # --------------------------
  # 💬 SEND PLATFORM FEE SMS
  # --------------------------
  def send_platform_fee_sms(phone_number, due_date, invoice_number, username, plan_name, amount)
    provider = ActsAsTenant.current_tenant.sms_provider_setting&.sms_provider

    message = "Hello #{username}, your invoice #{invoice_number} for #{plan_name} has been generated. Amount due: #{amount} KES by #{due_date.strftime('%B %d, %Y')}. Please settle to continue using the platform."

    case provider
    when 'TextSms'
      send_textsms(phone_number, message)
    when 'SMS leopard'
      send_sms_leopard(phone_number, message)
    else
      Rails.logger.info "No valid SMS provider configured"
    end
  end

  def send_textsms(phone_number, message)
    api_key = SmsSetting.find_by(sms_provider: 'TextSms')&.api_key
    partnerID = SmsSetting.find_by(sms_provider: 'TextSms')&.partnerID
    shortcode = SmsSetting.find_by(sms_provider: 'TextSms')&.sender_id

    uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
    params = {
      apikey: api_key,
      message: message,
      mobile: phone_number,
      partnerID: partnerID,
      shortcode: shortcode
    }
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    Rails.logger.info "SMS TextSms response: #{response.body}"
  end

  def send_sms_leopard(phone_number, message)
    api_key = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_key
    api_secret = SmsSetting.find_by(sms_provider: 'SMS leopard')&.api_secret

    uri = URI("https://api.smsleopard.com/v1/sms/send")
    params = {
      username: api_key,
      password: api_secret,
      message: message,
      destination: phone_number,
      source: "PLATFORM"
    }
    uri.query = URI.encode_www_form(params)
    response = Net::HTTP.get_response(uri)
    Rails.logger.info "SMS Leopard response: #{response.body}"
  end

  # --------------------------
  # 🆔 INVOICE NUMBER
  # --------------------------
  def generate_invoice_number
    "INV#{rand(1000..9999)}"
  end
end