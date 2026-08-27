class TenantSmsWalletController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  # KES per credit — same "set this before going live" note as SHORT_CODE
  # above. Move to ENV or a real settings row once you've decided which.
  SELL_PRICE_PER_SMS = ENV.fetch('SMS_WALLET_SELL_PRICE', '0.60').to_f

  def balance
    wallet = TenantSmsWallet.find_or_create_by!(account_id: @account.id)
    render json: {
      balance: wallet.balance,
      sell_price_per_sms: SELL_PRICE_PER_SMS,
      enabled: PlatformBulkSmsService::ENABLED
    }
  end

  def purchase
    quantity = params[:quantity].to_i
    return render json: { error: 'Minimum purchase is 10 credits' }, status: :unprocessable_entity if quantity < 10

    headroom = PlatformBulkSmsBalanceService.sellable_headroom

    # if headroom.nil?
    #   return render json: {
    #     error: 'SMS purchases are temporarily unavailable. Please contact your platform admin.'
    #   }, status: :service_unavailable
    # end

    # if quantity > headroom
    #   return render json: {
    #     error: 'SMS credits are temporarily unavailable. Please contact your platform admin.'
    #   }, status: :unprocessable_entity
    # end

    amount = (quantity * SELL_PRICE_PER_SMS).round(2)

    wallet = TenantSmsWallet.find_or_create_by!(account_id: @account.id)
    txn = TenantSmsWalletTransaction.create!(
      account_id: @account.id, tenant_sms_wallet_id: wallet.id,
      transaction_type: 'purchase', quantity: quantity, amount: amount,
      status: 'pending'
    )

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

  def purchase_status
    txn = TenantSmsWalletTransaction.find_by(account_id: @account.id, reference: params[:reference])
    return render json: { error: 'Not found' }, status: :not_found unless txn

    render json: { status: txn.status, balance: TenantSmsWallet.find_by(account_id: @account.id)&.balance }
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