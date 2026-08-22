# app/controllers/paystack_callbacks_controller.rb
class PaystackCallbacksController < ApplicationController
  # skip_before_action :verify_authenticity_token, raise: false

  def hotspot_callback
    payload = request.raw_post

    Rails.logger.info "========== PAYSTACK WEBHOOK RECEIVED =========="
    Rails.logger.info payload

    event = JSON.parse(payload) rescue {}

    Rails.logger.info "Paystack event: #{event['event']}"
    Rails.logger.info "Paystack reference: #{event.dig('data', 'reference')}"

    head :ok
  end

  private

  def valid_signature?(payload)
    account = ActsAsTenant.without_tenant { Account.find_by(subdomain: request.headers['X-Subdomain']) }
    setting = account && PaystackSetting.find_by(account_id: account.id)
    return false unless setting&.secret_key.present?

    expected = OpenSSL::HMAC.hexdigest('sha512', setting.secret_key, payload)
    ActiveSupport::SecurityUtils.secure_compare(expected, request.headers['HTTP_X_PAYSTACK_SIGNATURE'].to_s)
  end

  def process_success(revenue)
    revenue.update!(status: 'Completed', time_paid: Time.current)

    session = TemporarySession.find_by(checkout_request_id: revenue.checkout_request_id)
    return unless session

    hotspot_package = HotspotPackage.find_by(name: session.hotspot_package, account_id: session.account_id)
    return unless hotspot_package

    voucher = HotspotVoucher.create!(
      package: session.hotspot_package, phone: session.phone_number, voucher: session.voucher_code,
      mac: session.mac, ip: session.ip, checkout_request_id: revenue.checkout_request_id,
      account_id: session.account_id, hotspot_package_id: hotspot_package.id, status: 'active'
    )
    session.update!(hotspot_voucher_id: voucher.id)
    revenue.update!(hotspot_voucher_id: voucher.id)

    nas_router = NasRouter.find_by(name: hotspot_package.nas_router, account_id: session.account_id)
    return unless nas_router

    begin
      response = RestClient::Request.execute(
        method: :post, url: "http://#{nas_router.ip_address}/rest/ip/hotspot/active/login",
        user: nas_router.username, password: nas_router.password,
        payload: { ip: session.ip, user: voucher.voucher, password: voucher.voucher }.to_json,
        headers: { content_type: :json, accept: :json }, timeout: 5, open_timeout: 3
      )
      if response.code == 200
        session.update!(connected: true, status: 'used', paid: true)
        voucher.update!(status: 'used', last_logged_in: Time.current, used_voucher: true, login_by: 'Paystack STK')
      end
    rescue => e
      Rails.logger.warn "Paystack hotspot callback: router login failed: #{e.message}"
    end
  end
end