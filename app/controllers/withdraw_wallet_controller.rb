class WithdrawWalletController < ApplicationController

  set_current_tenant_through_filter

  before_action :set_tenant

  # Simple in-request guard against double-submit races using an idempotency key.
  # NOTE: For full production robustness, back this with a DB-backed unique index
  # (e.g. an `idempotency_keys` table with a unique constraint on `key`) instead of
  # Rails.cache, since cache can be evicted/cleared and isn't durable across restarts.
  IDEMPOTENCY_TTL = 5.minutes

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def withdraw_from_wallet
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    return render json: { error: 'Invalid tenant' }, status: :not_found unless @account

    wallet_type      = params[:wallettype]
    requested_amount = params[:amount].to_f
    phone_number     = params[:phonenumber]
    description      = params[:description]
    idempotency_key  = params[:idempotency_key].presence || request.headers['X-Idempotency-Key']

    if requested_amount <= 0
      return render json: { error: 'Invalid amount' }, status: :unprocessable_entity
    end

    if phone_number.blank?
      return render json: { error: 'Phone number is required' }, status: :unprocessable_entity
    end

    unless idempotency_key.present?
      return render json: { error: 'Missing idempotency key' }, status: :unprocessable_entity
    end

    # ---- Idempotency guard: reject a duplicate submit within the TTL window ----
    cache_key = "withdrawal_lock:#{@account.id}:#{idempotency_key}"
    unless Rails.cache.write(cache_key, true, unless_exist: true, expires_in: IDEMPOTENCY_TTL)
      return render json: { error: 'Duplicate withdrawal request already in progress' },
                    status: :conflict
    end

    # ---- Log the attempt up front, before we call out to Safaricom ----
    withdrawal_log = Withdrawal.create!(
      account: @account,
      wallet_type: wallet_type,
      amount: requested_amount,
      phone_number: phone_number,
      description: description,
      idempotency_key: idempotency_key,
      status: 'pending'
    )

    begin
      revenue_klass = wallet_type == 'hotspot' ? HotspotMpesaRevenue : PpPoeMpesaRevenue
      revenue_label = wallet_type == 'hotspot' ? 'hotspot revenue' : 'pppoe revenue'

      result = process_withdrawal(
        revenue_klass: revenue_klass,
        revenue_label: revenue_label,
        requested_amount: requested_amount,
        phone_number: phone_number
      )

      if result[:success]
        withdrawal_log.update!(status: 'completed', paid_out_at: Time.current)
        render json: { success: true, withdrawn: requested_amount }
      else
        withdrawal_log.update!(status: 'failed', error_message: result[:error])
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    rescue => e
      withdrawal_log.update!(status: 'failed', error_message: e.message)
      raise
    ensure
      Rails.cache.delete(cache_key)
    end
  end

  # GET /api/admin/transactions
  # Returns the withdrawal log for the current tenant, shaped for the
  # frontend's transaction history panel.
  def transactions
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    return render json: { error: 'Invalid tenant' }, status: :not_found unless @account

    records = Withdrawal.where(account: @account)
                         .order(created_at: :desc)
                         .limit(100)

    render json: records.map { |w|
      {
        id: w.id,
        type: 'withdrawal',
        walletType: w.wallet_type,
        amount: w.amount.to_f,
        phoneNumber: w.phone_number,
        description: w.description,
        status: w.status,
        errorMessage: w.error_message,
        timestamp: w.paid_out_at || w.created_at
      }
    }
  end

  private

  # Performs the balance check, row-locking, and disbursement as one atomic unit.
  # Locking the unpaid revenue rows for the duration of the transaction prevents
  # two concurrent requests from both reading the same "available balance" and
  # both succeeding — the second request will block until the first commits,
  # then re-evaluate against the now-updated (locked) data.
  





def process_withdrawal(revenue_klass:, revenue_label:, requested_amount:, phone_number:)
  outcome = { success: false, error: nil }

  ActiveRecord::Base.transaction do
    # Materialize + lock the actual rows (plain SELECT ... FOR UPDATE, no aggregate)
    unpaid_revenues = revenue_klass
                        .where(paid_out: false, status: "Completed")
                        .order(:created_at)
                        .lock!
                        .to_a

    # Sum in Ruby now that we have real records, not a SQL aggregate query
    available_balance = unpaid_revenues.sum(&:amount)

    if available_balance < requested_amount
      outcome[:error] = "Insufficient wallet balance for #{revenue_label}"
      raise ActiveRecord::Rollback
    end

    selected_revenues = []
    running_total = 0.0

    unpaid_revenues.each do |revenue|
      break if running_total >= requested_amount

      selected_revenues << revenue
      running_total += revenue.amount.to_f
    end

    selected_revenues.each do |revenue|
      revenue.update!(paid_out: true, paid_out_at: Time.current, amount_disbursed: revenue.amount)
    end

    success = send_b2c(phone_number, requested_amount, @account)

    unless success
      outcome[:error] = "B2C failed for #{revenue_label}"
      raise ActiveRecord::Rollback
    end

    outcome[:success] = true
  end

  outcome
end



  def send_b2c(phone_number, amount, tenant)
    token = fetch_access_token(tenant)
    mpesa_setting = tenant.hotspot_mpesa_setting

    return false unless token

    payload = {
      OriginatorConversationID: "600997_Test_32et3241ed8yu",
      InitiatorName: mpesa_setting&.api_initiator_username || ENV['API_INITIATOR_USERNAME'],
      SecurityCredential: mpesa_setting&.api_initiator_password || ENV['B2C_API_INITIATOR_PASSWORD'],
      CommandID: "BusinessPayment",
      Amount: amount,
      PartyA: mpesa_setting&.short_code || ENV['B2C_SHORTCODE'],
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

      if parsed["ResultCode"] == "0" || parsed["ResponseCode"] == "0"
        Rails.logger.info "B2C success: #{response.body}"
        true
      else
        Rails.logger.info "B2C API returned error: #{parsed}"
        false
      end
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.info "B2C exception: #{e.response.body}"
      false
    end
  end

  def fetch_access_token(tenant)
    mpesa_setting = tenant.hotspot_mpesa_setting

    consumer_key    = mpesa_setting&.consumer_key || ENV['CONSUMER_KEY']
    consumer_secret = mpesa_setting&.consumer_secret || ENV['CONSUMER_SECRET']

    response = RestClient.get(
      "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials",
      Authorization: "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}"
    )

    JSON.parse(response.body)["access_token"]
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.info "Token error: #{e.response}"
    nil
  end
def format_phone(phone)
  digits = phone.to_s.strip.gsub(/\D/, '')

  case digits
  when /\A0\d{9}\z/
    digits.sub(/\A0/, '254')
  when /\A254\d{9}\z/
    digits
  when /\A7\d{8}\z/, /\A1\d{8}\z/
    "254#{digits}"
  else
    digits
  end
end
end