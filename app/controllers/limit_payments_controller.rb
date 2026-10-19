class LimitPaymentsController < ApplicationController
  # Public JSON endpoints: the React page and PayHero's webhook send no CSRF token
  # skip_before_action :verify_authenticity_token

  CHANNEL_ID = 13890
  RECONCILE_AFTER = 25.seconds



  # POST /api/make_limit_payment
  # body: { id_number, phone, new_limit }
  def create
    id_number = params[:id_number].to_s.strip
    phone     = normalize_phone(params[:phone])
    new_limit = params[:new_limit].to_i
    fee       = LimitPayment.fee_for(new_limit)

    return render_error('Enter a valid ID number') unless id_number.match?(/\A\d{6,10}\z/)
    return render_error('Enter a valid Safaricom number') unless phone
    return render_error('Invalid limit selected') unless fee

    payment = LimitPayment.create!(
      id_number: id_number,
      phone:     phone,
      new_limit: new_limit,
      amount:    fee
    )

    result = PayheroService.initiate_stk_push(
      amount:             fee,
      phone:              phone,
      channel_id:         CHANNEL_ID,
      external_reference: payment.external_reference,
      customer_name:      "ID #{id_number}",
      callback_url:       callback_url
    )

    if result[:success]
      resp = result[:response] || {}
      payment.update!(
        payhero_reference:   resp['reference'],
        checkout_request_id: resp['CheckoutRequestID']
      )
      render json: { success: true, reference: payment.external_reference }
    else
      Rails.logger.warn "[LimitPayment] STK failed #{payment.external_reference}: #{result[:error]}"
      payment.mark_failed!(desc: result[:error])
      render_error('Could not send the M-Pesa prompt. Please try again.', :bad_gateway)
    end
  rescue StandardError => e
    Rails.logger.error "[LimitPayment] create error: #{e.class} #{e.message}"
    render_error('Something went wrong. Please try again.', :internal_server_error)
  end

  # GET /api/limit_payment_status/:reference
  def status
    payment = LimitPayment.find_by(external_reference: params[:reference])
    return render json: { success: false, error: 'Not found' }, status: :not_found unless payment

    reconcile!(payment)

    render json: {
      success: true,
      status: payment.status,
      mpesa_receipt: payment.mpesa_receipt,
      message: payment.failed? ? payment.result_desc : nil
    }
  end

  # POST /api/limit_payment_callback  (PayHero -> us)
  def callback
    data = params.to_unsafe_h
    resp = data['response'].is_a?(Hash) ? data['response'] : data
    ref  = resp['ExternalReference'] || resp['external_reference']

    payment = LimitPayment.find_by(external_reference: ref)
    return head :ok unless payment

    if resp['Amount'].present? && resp['Amount'].to_i != payment.amount
      Rails.logger.error "[LimitPayment] amount mismatch #{ref}: got #{resp['Amount']}, expected #{payment.amount}"
      return head :ok
    end

    success = resp['ResultCode'].to_s == '0' || resp['Status'].to_s.casecmp?('success')

    if success
      payment.mark_paid!(receipt: resp['MpesaReceiptNumber'], payload: data)
    else
      payment.mark_failed!(desc: resp['ResultDesc'] || 'Payment was not completed', payload: data)
    end

    head :ok
  rescue StandardError => e
    Rails.logger.error "[LimitPayment] callback error: #{e.class} #{e.message}"
    head :ok
  end

  private

  def callback_url
    ENV['LIMIT_PAYMENT_CALLBACK_URL'].presence || 'https://owitech.co.ke/limit_payment_callback'
  end

  # Fallback if the callback never arrives: ask PayHero directly.
  # Check the field names below against a real transaction-status response.
  def reconcile!(payment)
    return unless payment.pending? && payment.created_at < RECONCILE_AFTER.ago

    ref    = payment.payhero_reference.presence || payment.external_reference
    result = PayheroService.transaction_status(ref)
    return unless result[:success]

    body = result[:response] || {}
    case body['status'].to_s.upcase
    when 'SUCCESS'
      payment.mark_paid!(receipt: body['provider_reference'], payload: body)
    when 'FAILED'
      payment.mark_failed!(desc: body['error_message'] || 'Payment failed', payload: body)
    end
  end

  def normalize_phone(raw)
    d = raw.to_s.gsub(/\D/, '')
    return "254#{d[1..]}" if d.match?(/\A0[17]\d{8}\z/)
    return "254#{d}"      if d.match?(/\A[17]\d{8}\z/)
    return d              if d.match?(/\A254[17]\d{8}\z/)
    nil
  end

  def render_error(message, status = :unprocessable_entity)
    render json: { success: false, error: message }, status: status
  end
end