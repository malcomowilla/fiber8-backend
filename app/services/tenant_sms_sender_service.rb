class TenantSmsSenderService
  PLATFORM_PROVIDER = 'Owitech Bulk SMS'.freeze

  def self.uses_platform?(account_id)
    SmsSetting.find_by(account_id: account_id)&.sms_provider == PLATFORM_PROVIDER
  end




  def self.send_sms(phone_number, message, account_id, voucher, current_user: nil)
    result = PlatformBulkSmsService.send_sms(phone_number, message, account_id)
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