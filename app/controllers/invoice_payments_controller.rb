class InvoicePaymentsController < ApplicationController
  DARAJA_BASE = ENV.fetch('MPESA_BASE_URL', 'https://api.safaricom.co.ke')

  set_current_tenant_through_filter
  before_action :set_tenant, except: [:stk_callback]
  # Safaricom calls stk_callback with no session/subdomain: skip whatever
  # authentication filters your ApplicationController applies, e.g.
  # skip_before_action :authenticate_user!, only: [:stk_callback]
  skip_before_action :verify_authenticity_token, only: [:stk_callback], raise: false

  def set_tenant
    ActsAsTenant.current_tenant = Account.find_by!(subdomain: request.headers['X-Subdomain'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # POST /api/invoice_stk_push  { id:, phone_number: }
  def stk_push
    invoice = Invoice.find_by(id: params[:id])
    return render json: { error: 'Invoice not found' }, status: :not_found unless invoice
    return render json: { error: 'This invoice is already paid' }, status: :unprocessable_entity if invoice.status == 'paid'

    phone = normalize_msisdn(params[:phone_number])
    unless phone
      return render json: { error: 'Enter a valid Safaricom number, e.g. 0712345678' }, status: :unprocessable_entity
    end

    amount = invoice.total.to_i
    return render json: { error: 'Invalid invoice amount' }, status: :unprocessable_entity if amount < 1

    shortcode = ENV['PLATFORM_PAYBILL'].presence || ENV['B2C_SHORTCODE']
    passkey   = ENV['PASSKEY']
    timestamp = Time.now.in_time_zone('Nairobi').strftime('%Y%m%d%H%M%S')

    res = daraja_post('/mpesa/stkpush/v1/processrequest', {
      BusinessShortCode: shortcode,
      Password: Base64.strict_encode64("#{shortcode}#{passkey}#{timestamp}"),
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: amount,
      PartyA: phone,
      PartyB: shortcode,
      PhoneNumber: phone,
      CallBackURL: ENV.fetch('INVOICE_STK_CALLBACK_URL'),
      AccountReference: invoice.invoice_number,   # Daraja limit: 12 chars
      TransactionDesc: "Invoice #{invoice.invoice_number}"
    })

    checkout_id = res['CheckoutRequestID']
    if res['ResponseCode'].to_s == '0' && checkout_id
      Rails.cache.write("invoice_stk:#{checkout_id}",
        { invoice_id: invoice.id, state: 'pending', started_at: Time.current.to_f },
        expires_in: 30.minutes)
      # Lets the C2B confirmation know where to send the SMS (C2B MSISDN is often masked)
      Rails.cache.write("invoice_phone:#{invoice.id}", phone, expires_in: 2.hours)

      render json: { message: 'Check your phone and enter your M-Pesa PIN', checkout_request_id: checkout_id }
    else
      Rails.logger.warn "Invoice STK push failed: #{res}"
      render json: { error: res['errorMessage'] || res['CustomerMessage'] || 'Could not send the M-Pesa prompt, please try again' },
             status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Invoice STK push error: #{e.class} #{e.message}"
    render json: { error: 'M-Pesa is unreachable right now, please try again' }, status: :unprocessable_entity
  end

  # GET /api/invoice_payment_status?id=&checkout_request_id=
  def status
    invoice = Invoice.find_by(id: params[:id])
    return render json: { error: 'Invoice not found' }, status: :not_found unless invoice

    stk     = params[:checkout_request_id].present? ? Rails.cache.read("invoice_stk:#{params[:checkout_request_id]}") : nil
    payment = InvoicePayment.where(invoice_id: invoice.id).order(created_at: :desc).first

    if invoice.status == 'paid'
      render json: { state: 'paid', reference: payment&.reference, amount_paid: payment&.amount }
    elsif payment&.status == 'partial' && payment.created_at.to_f >= (stk&.dig(:started_at) || Time.current.to_f - 300)
      render json: { state: 'partial', reference: payment.reference, amount_paid: payment.amount,
                     balance: invoice.total.to_i - payment.amount.to_i }
    elsif stk && stk[:state] == 'failed'
      render json: { state: 'failed', message: stk[:message] }
    else
      render json: { state: 'pending' }
    end
  end

  # POST /api/invoice_stk_callback (Safaricom -> us)
  def stk_callback
    cb = params.to_unsafe_h.dig('Body', 'stkCallback') || {}
    checkout_id = cb['CheckoutRequestID']
    code = cb['ResultCode'].to_i

    if checkout_id && code != 0
      key = "invoice_stk:#{checkout_id}"
      if (entry = Rails.cache.read(key))
        Rails.cache.write(key, entry.merge(state: 'failed', message: friendly_stk_error(code, cb['ResultDesc'])),
                          expires_in: 30.minutes)
      end
    end
    # Success is deliberately ignored here: the C2B confirmation
    # (check_payment_status) is what marks the invoice paid.
    render json: { ResultCode: 0, ResultDesc: 'Accepted' }
  end

  private

  def friendly_stk_error(code, desc)
    case code
    when 1032 then 'You cancelled the payment request.'
    when 1    then 'Insufficient M-Pesa balance.'
    when 2001 then 'Wrong M-Pesa PIN entered.'
    when 1037 then 'The request timed out on your phone. Please try again.'
    else desc.presence || 'Payment was not completed.'
    end
  end

  def normalize_msisdn(raw)
    d = raw.to_s.gsub(/\D/, '')
    d = "254#{d[1..]}" if d.start_with?('0')
    d = "254#{d}" if d.match?(/\A[17]\d{8}\z/)
    d.match?(/\A254[17]\d{8}\z/) ? d : nil
  end

  def daraja_token
    uri = URI("#{DARAJA_BASE}/oauth/v1/generate?grant_type=client_credentials")
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(ENV['CONSUMER_KEY'], ENV['CONSUMER_SECRET'])
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) { |h| h.request(req) }
    JSON.parse(res.body)['access_token']
  end

  def daraja_post(path, body)
    uri = URI("#{DARAJA_BASE}#{path}")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Bearer #{daraja_token}"
    req['Content-Type']  = 'application/json'
    req.body = body.to_json
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15) { |h| h.request(req) }
    JSON.parse(res.body)
  end
end




