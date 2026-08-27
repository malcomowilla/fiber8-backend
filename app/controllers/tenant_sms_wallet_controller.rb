class TenantSmsWalletController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  def balance
    wallet = TenantSmsWallet.find_or_create_by!(account_id: @account.id)
    setting = PlatformBulkSmsSetting.current
    render json: {
      balance: wallet.balance,
      sell_price_per_sms: setting.sell_price_per_sms,
      enabled: setting.enabled
    }
  end

  def purchase
    quantity = params[:quantity].to_i
    return render json: { error: 'Minimum purchase is 10 credits' }, status: :unprocessable_entity if quantity < 10

    setting = PlatformBulkSmsSetting.current
    amount = (quantity * setting.sell_price_per_sms).round(2)
    checkout_request_id = "smswallet_#{@account.id}_#{SecureRandom.hex(4)}"

    result = MpesaService.initiate_stk_push(
      params[:phone_number], amount,
      @account.hotspot_mpesa_setting&.short_code, @account.hotspot_mpesa_setting&.passkey,
      @account.hotspot_mpesa_setting&.consumer_key, @account.hotspot_mpesa_setting&.consumer_secret,
      request.headers['X-Subdomain'], checkout_request_id, checkout_request_id
    )

    if result[:success]
      TenantSmsWalletTransaction.create!(
        account_id: @account.id,
        tenant_sms_wallet_id: TenantSmsWallet.find_or_create_by!(account_id: @account.id).id,
        transaction_type: 'purchase', quantity: quantity, amount: amount,
        checkout_request_id: checkout_request_id, status: 'pending'
      )
      render json: { message: 'Check your phone to complete payment', checkout_request_id: checkout_request_id }
    else
      render json: { error: result[:error] || 'Failed to initiate payment' }, status: :unprocessable_entity
    end
  end

  def confirm_purchase
    txn = TenantSmsWalletTransaction.find_by(checkout_request_id: params[:checkout_request_id], status: 'pending')
    return render json: { error: 'Transaction not found' }, status: :not_found unless txn

    wallet = TenantSmsWallet.find_by(id: txn.tenant_sms_wallet_id)
    wallet.credit!(txn.quantity, reference: txn.checkout_request_id, amount: txn.amount, checkout_request_id: txn.checkout_request_id)
    txn.update!(status: 'completed')
    render json: { message: 'Credits added', balance: wallet.balance }
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