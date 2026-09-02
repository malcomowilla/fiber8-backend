


class TenantSidekiqService
  PLATFORM_PROVIDER = 'Owitech Bulk SMS'.freeze

  def self.uses_platform?(account_id)
    SmsSetting.find_by(account_id: account_id)&.sms_provider == PLATFORM_PROVIDER
  end

  def self.send_sms(phone_number, message, account_id)
    begin
      result = PlatformSendSmsService.send_sms(
        phone_number,
        message,
        account_id
      )

      SystemAdminSm.create!(
        user: phone_number,
        message: message,
        status: result[:success] ? (result[:status] || 'Sent') : result[:error],
        date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
        system_user:  'system',
        sms_provider: PLATFORM_PROVIDER,
        account_id: account_id
      )

      result

    rescue StandardError => e
      Rails.logger.error(
        "TenantPaymentSenderService failed: #{e.class}: #{e.message}"
      )

      SystemAdminSm.create!(
        user: phone_number,
        message: message,
        status: "Failed: #{e.message}",
        date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
        system_user: current_user&.username || current_user&.email || 'system',
        sms_provider: PLATFORM_PROVIDER,
        account_id: account_id
      )

      {
        success: false,
        error: e.message
      }
    end
  end
end