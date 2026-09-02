# app/services/tenant_sms_sender_service.rb
class TenantSmsSenderService
  PLATFORM_PROVIDER = 'Owitech Bulk SMS'.freeze

  def self.uses_platform?(account_id)
    SmsSetting.find_by(account_id: account_id)&.sms_provider == PLATFORM_PROVIDER
  end


# TenantSmsSenderService.send_sms(params[:phone], message, 
# ActsAsTenant.current_tenant.id, voucher, 
# current_user: current_user)

  def self.send_sms(phone_number, message, account_id, voucher, current_user)
    wallet = TenantSmsWallet.find_or_create_by!(account_id: account_id)

    if wallet.balance < 1
      SystemAdminSm.create!(
        user: phone_number, message: message, status: 'Failed: insufficient SMS balance',
        date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
        system_user: current_user&.username || current_user&.email || 'system',
        sms_provider: PLATFORM_PROVIDER, account_id: account_id
      )
      return { success: false, error: 'Insufficient SMS balance. Please top up to continue sending.' }
    end

    result = PlatformBulkSmsService.send_sms(phone_number, message, account_id, voucher, current_user)

    # Only charge for sends that actually went out — a failed send
    # shouldn't cost the tenant a credit.
    if result[:success]
      voucher_ref = voucher.respond_to?(:voucher) ? "voucher:#{voucher.voucher}" : nil
      wallet.debit!(1, reference: voucher_ref)
    end

    SystemAdminSm.create!(
      user: phone_number, message: message,
      status: result[:success] ? (result[:status] || 'Sent') : result[:error],
      date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
      system_user: current_user&.username || current_user&.email || 'system',
      sms_provider: PLATFORM_PROVIDER, account_id: account_id
    )

    result
  end
end