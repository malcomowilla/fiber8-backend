# app/controllers/tenant_sms_wallet_controller.rb — full replacement
class TenantSmsWalletController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  SELL_PRICE_PER_SMS = ENV.fetch('SMS_WALLET_SELL_PRICE', '0.60').to_f

  def balance
    wallet = TenantSmsWallet.for_current_tenant
    render json: {
      balance: wallet.balance,
      sell_price_per_sms: SELL_PRICE_PER_SMS,
      enabled: PlatformBulkSmsService::ENABLED
    }
  end

  # Powers the 4-card stats strip: balance, sent this month, total sent,
  # total purchased — all derived from the transaction ledger, no
  # separate counters to keep in sync.
  def stats
    wallet = TenantSmsWallet.for_current_tenant
    month_range = Time.current.beginning_of_month..Time.current.end_of_month

    sent_this_month = wallet.transactions
                             .where(transaction_type: 'send', status: 'completed')
                             .where(created_at: month_range)
                             .sum(:quantity)

    total_sent = wallet.transactions
                        .where(transaction_type: 'send', status: 'completed')
                        .sum(:quantity)

    total_purchased = wallet.transactions
                             .where(transaction_type: 'purchase', status: 'completed')
                             .sum(:quantity)

    render json: {
      balance: wallet.balance,
      sent_this_month: sent_this_month,
      total_sent: total_sent,
      total_purchased: total_purchased
    }
  end

  def purchase
    quantity = params[:quantity].to_i
    return render json: { error: 'Minimum purchase is 10 credits' }, status: :unprocessable_entity if quantity < 10

    headroom = PlatformBulkSmsBalanceService.sellable_headroom

    if headroom.nil?
      return render json: {
        error: 'SMS purchases are temporarily unavailable. Please contact your platform admin.'
      }, status: :service_unavailable
    end

    if quantity > headroom
      return render json: {
        error: 'SMS credits are temporarily unavailable. Please contact your platform admin.'
      }, status: :unprocessable_entity
    end

    amount = (quantity * SELL_PRICE_PER_SMS).round(2)

    # This is the "always create a record" fix: the pending purchase row
    # is created here, before payment even starts, and the M-Pesa
    # callback completes THIS row rather than creating a second one.
    _wallet, txn = TenantSmsWallet.initiate_purchase!(account_id: @account.id, quantity: quantity, amount: amount)

    account_reference = "smswallet_#{@account.id}_#{txn.id}"

    result = TenantSmsWalletMpesaService.initiate_stk_push(
      params[:phone_number], amount, account_reference, "SMS credits purchase"
    )

    if result[:success]
      checkout_request_id = result[:response]&.dig('CheckoutRequestID')
      txn.update!(checkout_request_id: checkout_request_id, reference: account_reference)
      render json: { message: 'Check your phone to complete payment', checkout_request_id: checkout_request_id }
    else
      txn.update!(status: 'failed')
      render json: { error: result[:error] || 'Failed to initiate payment' }, status: :unprocessable_entity
    end
  end

  # Polled by the frontend after STK push. Just reads the transaction's
  # current status — the M-Pesa confirmation callback (in
  # HotspotVouchersController#check_payment_status) is what actually
  # completes it.
  def confirm
    txn = TenantSmsWalletTransaction.find_by(account_id: @account.id, checkout_request_id: params[:checkout_request_id])
    return render json: { status: 'not_found' }, status: :not_found unless txn

    wallet = TenantSmsWallet.for_current_tenant
    render json: { status: txn.status, balance: wallet.balance, quantity: txn.quantity }
  end

  def purchase_status
    txn = TenantSmsWalletTransaction.find_by(account_id: @account.id, reference: params[:reference])
    return render json: { error: 'Not found' }, status: :not_found unless txn

    render json: { status: txn.status, balance: TenantSmsWallet.for_current_tenant.balance }
  end

  private

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end
end