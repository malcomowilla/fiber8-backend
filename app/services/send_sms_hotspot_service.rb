class SendSmsHotspotService
  def self.send_sms(voucher_code, data, checkout_request_id)
    voucher = HotspotVoucher.find_by(voucher: voucher_code)
    return unless voucher

    revenue = HotspotMpesaRevenue.find_by(checkout_request_id: checkout_request_id)

    if revenue
      revenue.update!(
        amount: data["TransAmount"],
        reference: data["TransID"],
        voucher: voucher_code,
        payment_method: "Mpesa",
        time_paid: data["TransTime"],
        name: data["FirstName"],
        account_id: voucher.account_id,
        status: "Completed",
        hotspot_voucher_id: voucher.id
      )
    end

    return if voucher.sms_sent_at_voucher.present?

    account = Account.find_by(id: voucher.account_id)
    return unless account

    ActsAsTenant.with_tenant(account) do
      send_sms_for_tenant(voucher, account)
    end
  end

  class << self
    private

    def send_sms_for_tenant(voucher, tenant)
      sms_setting = tenant.sms_provider_setting

      voucher.update(sms_sent_at_voucher: Time.now, sms_sent: true)

      if sms_setting.blank?
        Rails.logger.info "[SendSmsHotspotService] Tenant #{tenant.id} has no SMS provider set, skipping SMS for voucher #{voucher.voucher}."
        return
      end

      message = build_message(voucher, tenant)

      case sms_setting.sms_provider


      when 'Owitech Bulk SMS'
        TenantWalletSenderService.send_sms(voucher.phone, message, tenant.id, current_user: nil)

      when "SMS leopard"
        send_voucher_sms_leopard(voucher, tenant, message)
      when "TextSms"
        send_voucher_text_sms(voucher, tenant, message)
      when "Talk Sasa"
        send_voucher_talksasa(voucher, tenant, message)
      else
        Rails.logger.info "[SendSmsHotspotService] Tenant #{tenant.id} has unknown SMS provider: #{sms_setting.sms_provider}."
      end
    end

    # Same template lookup/fallback as HotspotVouchersController#send_voucher —
    # uses whichever "single" HotspotSmsTemplate is toggled active for the tenant.
    def build_message(voucher, tenant)
      package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
      company_name = tenant.company_setting&.company_name.to_s

      data = {
        customer_phone: voucher.phone,
        plan_name: package&.name,
        voucher_code: voucher.voucher,
        username: voucher.voucher,
        password: voucher.voucher,
        validity: voucher.expiration&.strftime("%B %d, %Y at %I:%M %p"),
        price: package&.price,
        company_name: company_name,
        voucher_count: package&.shared_users,
        voucher_list: HotspotSmsTemplate.format_voucher_list(
          [{ code: voucher.voucher, username: voucher.voucher, password: voucher.voucher }]
        )
      }

      template = HotspotSmsTemplate.active_for(tenant.id, 'single')
      return template.render(data) if template

      expiry_str = data[:validity] ? " Valid until #{data[:validity]}." : ""
      "Your voucher code is: #{voucher.voucher}.#{expiry_str} Enjoy browsing! (#{company_name})"
    end

    def send_voucher_talksasa(voucher, tenant, message)
      formatted_phone_number = "254#{voucher.phone.gsub(/\A0/, '')}"

      sms_setting = SmsSetting.find_by(account_id: tenant.id, sms_provider: 'Talk Sasa')
      api_key   = sms_setting&.api_key
      sender_id = sms_setting&.sender_id

      uri = URI.parse("https://bulksms.talksasa.com/api/v3/sms/send")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"]  = "application/json"
      request["Accept"]        = "application/json"
      request.body = {
        recipient: formatted_phone_number,
        sender_id: sender_id,
        type: "plain",
        message: message
      }.to_json

      response = http.request(request)
      Rails.logger.info "[SendSmsHotspotService] TalkSasa Response: #{response.body}"

      if response.is_a?(Net::HTTPSuccess)
        sms_data = JSON.parse(response.body) rescue {}

        SystemAdminSm.create!(
          user: voucher.phone,
          message: message,
          status: sms_data['status'],
          date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
          system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Talk Sasa'
        )
      else
        Rails.logger.info "[SendSmsHotspotService] Failed to send SMS with Talk Sasa: #{response.code} - #{response.body}"

        SystemAdminSm.create!(
          user: voucher.phone,
          message: message,
          status: "Failed: #{response.code}",
          date: Time.now.strftime("%B %d, %Y at %I:%M %p"),
          system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Talk Sasa'
        )
      end
    end

    def send_voucher_sms_leopard(voucher, tenant, message)
      sms_setting = tenant.sms_setting
      api_key     = sms_setting.api_key
      api_secret  = sms_setting.api_secret

      uri = URI("https://api.smsleopard.com/v1/sms/send")
      uri.query = URI.encode_www_form(
        username:    api_key,
        password:    api_secret,
        message:     message,
        destination: voucher.phone,
        source:      "SMS_TEST"
      )

      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        sms_data = JSON.parse(response.body) rescue {}
        record = sms_data.dig('recipients', 0) || sms_data.dig('responses', 0) || {}

        SystemAdminSm.create!(
          user:    record['number'] || record['mobile'] || voucher.phone,
          message: message,
          status:  record['status'] || record['response-description'],
          date:    Time.now.strftime("%B %d, %Y at %I:%M %p"),
          system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Sms Leopard'
        )
      else
        Rails.logger.info "[SendSmsHotspotService] Failed to send SMS with Sms Leopard: #{response.code} - #{response.body}"

        SystemAdminSm.create!(
          user:    voucher.phone,
          message: message,
          status:  "Failed: #{response.code}",
          date:    Time.now.strftime("%B %d, %Y at %I:%M %p"),
          system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Sms Leopard'
        )
      end
    end

    def send_voucher_text_sms(voucher, tenant, message)
      sms_setting = tenant.sms_setting
      api_key     = sms_setting.api_key
      partnerID   = sms_setting.partnerID
      shortcode   = sms_setting.sender_id

      uri = URI("https://sms.textsms.co.ke/api/services/sendsms")
      uri.query = URI.encode_www_form(
        apikey:    api_key,
        message:   message,
        mobile:    voucher.phone,
        partnerID: partnerID,
        shortcode: shortcode
      )

      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        sms_data = JSON.parse(response.body) rescue {}
        record = sms_data.dig('responses', 0) || {}

        SystemAdminSm.create!(
          user:    record['mobile'] || voucher.phone,
          message: message,
          status:  record['response-description'],
          date:    Time.now.strftime("%B %d, %Y at %I:%M %p"),
          system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Text Sms'
        )
      else
        Rails.logger.info "[SendSmsHotspotService] Failed to send SMS with TextSms: #{response.code} - #{response.body}"

        SystemAdminSm.create!(
          user:    voucher.phone,
          message: message,
          status:  "Failed: #{response.code}",
          date:    Time.now.strftime("%B %d, %Y at %I:%M %p"),
          system_user: 'system',
          account_id: tenant.id,
          sms_provider: 'Text Sms'
        )
      end
    end
  end
end