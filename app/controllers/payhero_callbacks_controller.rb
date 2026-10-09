class PayheroCallbacksController < ApplicationController
  include BroadcastsHotspotPayments

  skip_before_action :verify_authenticity_token, raise: false

  # POST /paystack_owitech_callback  (and /api/paystack_owitech_callback)
  def hotspot_callback
    raw = request.body.read
    Rails.logger.info "PAYHERO CALLBACK: #{raw}"

    payload = JSON.parse(raw) rescue {}
    data    = payload['response'].is_a?(Hash) ? payload['response'] : payload

    reference = data['ExternalReference'].to_s
    return head :ok unless reference.start_with?('hotspot_')

    session_id, _voucher_code = reference.sub('hotspot_', '').split('_', 2)
    session = ActsAsTenant.without_tenant { TemporarySession.find_by(session: session_id) }
    return head :ok unless session

    account = Account.find_by(id: session.account_id)
    return head :ok unless account

    ActsAsTenant.with_tenant(account) do
      session.with_lock do
        next if session.paid

        receipt = data['MpesaReceiptNumber'].to_s
        revenue = HotspotMpesaRevenue.find_by(checkout_request_id: reference)

        if callback_says_success?(data) && payment_verified?(receipt)
          fulfill_hotspot(session, revenue, data, receipt)
        elsif callback_says_failed?(data)
          revenue&.update(status: 'Cancelled')
        else
          Rails.logger.warn "payhero: callback for #{reference} not confirmed, leaving pending"
        end
      end
    end

    head :ok
  rescue StandardError => e
    Rails.logger.error "payhero callback error: #{e.class} #{e.message}\n#{e.backtrace.first(8).join("\n")}"
    head :ok
  end

  private

  def callback_says_success?(data)
    return data['ResultCode'].to_i.zero? unless data['ResultCode'].nil?
    data['Status'].to_s.casecmp('success').zero?
  end

  def callback_says_failed?(data)
    return data['ResultCode'].to_i != 0 unless data['ResultCode'].nil?
    data['Status'].to_s.casecmp('failed').zero?
  end

  # Never trust the callback body alone.
  def payment_verified?(receipt)
    return false if receipt.blank?
    result = PayheroService.transaction_status(receipt)
    result[:success] && result[:response]['status'].to_s.upcase == 'SUCCESS'
  end

  def fulfill_hotspot(session, revenue, data, receipt)
    Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone

    package = HotspotPackage.find_by(name: session.hotspot_package, account_id: session.account_id)
    unless package
      Rails.logger.error "payhero: package #{session.hotspot_package} not found for session #{session.id}"
      return
    end

    voucher = HotspotVoucher.create!(
      package: session.hotspot_package, phone: session.phone_number,
      voucher: session.voucher_code, mac: session.mac, ip: session.ip,
      checkout_request_id: session.checkout_request_id,
      account_id: session.account_id, hotspot_package_id: package.id, status: 'active'
    )
    session.update(hotspot_voucher_id: voucher.id)

    revenue&.update(status: 'Completed', reference: receipt, time_paid: Time.current,
                    hotspot_voucher_id: voucher.id)

    seconds = validity_seconds(package)
    voucher.update(expiration: (Time.current + seconds).strftime("%B %d, %Y at %I:%M %p")) if seconds

    realtime  = HotspotSetting.find_by(account_id: session.account_id)&.voucher_expiration == 'Real-time expiration'
    nas_setting = NasSetting.find_by(account_id: session.account_id)
    use_radius  = nas_setting ? ActiveModel::Type::Boolean.new.cast(nas_setting.use_radius) : true

    if use_radius
      create_radius_user(voucher.voucher, package, session.account_id, accumulated: !realtime)
    else
      sync_native(voucher, package, limit_uptime: !realtime)
    end

    amount = data['Amount']
    phone  = session.phone_number

    begin
      SendSmsHotspotService.send_sms(
        voucher.voucher,
        { 'TransAmount' => amount, 'FirstName' => nil, 'TransID' => receipt, 'MSISDN' => phone },
        session.checkout_request_id
      )
    rescue => e
      Rails.logger.error "payhero: SendSmsHotspotService failed: #{e.message}"
    end

    broadcast_hotspot_payment(
      account_id: session.account_id, kind: 'voucher', amount: amount,
      package: session.hotspot_package, name: phone, phone: phone,
      payment_method: 'PayHero', reference: receipt
    )

    begin
      HotspotLoyaltyService.award_points(
        account_id: session.account_id, phone: phone, name: nil,
        amount: amount, package: session.hotspot_package, reference: receipt
      )
    rescue => e
      Rails.logger.error "payhero: loyalty award failed: #{e.message}"
    end

    login_on_router(session, voucher, package)
  end

  def validity_seconds(package)
    return nil unless package.validity.present? && package.validity_period_units.present?
    case package.validity_period_units.downcase
    when 'days'    then package.validity.to_i.days
    when 'hours'   then package.validity.to_i.hours
    when 'minutes' then package.validity.to_i.minutes
    end
  end

  def create_radius_user(code, package, account_id, accumulated:)
    group = "hotspot_#{account_id}_#{package.name.parameterize(separator: '_')}"

    RadCheck.find_or_initialize_by(username: code, account_id: account_id, radiusattribute: 'Cleartext-Password')
            .update!(op: ':=', value: code)
    RadUserGroup.find_or_create_by!(username: code, groupname: group, priority: 1, account_id: account_id)

    seconds = validity_seconds(package)
    return unless seconds

    if accumulated
      RadCheck.find_or_initialize_by(username: code, account_id: account_id, radiusattribute: 'Max-All-Session')
              .update!(op: ':=', value: seconds.to_i.to_s)
    else
      RadCheck.find_or_initialize_by(username: code, account_id: account_id, radiusattribute: 'Expiration')
              .update!(op: ':=', value: (Time.current + seconds).strftime("%d %b %Y %H:%M:%S"))
    end
  end

  def sync_native(voucher, package, limit_uptime:)
    nas = NasRouter.find_by(name: package.nas_router, account_id: voucher.account_id)
    return voucher.update(sync_status: 'failed', sync_error: 'Router not found') unless nas

    words = ['/ip/hotspot/user/add', "=name=#{voucher.voucher}", "=password=#{voucher.voucher}", "=profile=#{package.name}"]
    words << "=limit-uptime=#{mikrotik_validity(package)}" if limit_uptime

    client = RouterosApiClient.new(nas.ip_address, nas.username.to_s, nas.password.to_s, timeout: 10)
    client.connect
    reply = client.talk(words)

    if reply.last.first == '!trap'
      msg = reply.last.find { |w| w.start_with?('=message=') }&.sub('=message=', '') || 'Unknown MikroTik error'
      voucher.update(sync_status: 'failed', sync_error: msg)
    else
      voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)
    end
  rescue => e
    voucher.update(sync_status: 'failed', sync_error: e.message)
  ensure
    client&.close
  end

  def mikrotik_validity(pkg)
    suffix = { 'minutes' => 'm', 'hours' => 'h', 'days' => 'd', 'weeks' => 'w' }[pkg.validity_period_units.to_s]
    suffix ? "#{pkg.validity}#{suffix}" : '0s'
  end

  def login_on_router(session, voucher, package)
    nas = NasRouter.find_by(name: package.nas_router, account_id: package.account_id)
    unless nas
      Rails.logger.warn "payhero: no router for account #{session.account_id}"
      return
    end

    client = RouterosApiClient.new(nas.ip_address, nas.username.to_s, nas.password.to_s, timeout: 5)
    client.connect
    reply = client.talk([
      '/ip/hotspot/active/login',
      "=ip=#{session.ip}", "=user=#{voucher.voucher}", "=password=#{voucher.voucher}"
    ])

    if reply.last.first == '!trap'
      msg = reply.last.find { |w| w.start_with?('=message=') }&.sub('=message=', '')
      Rails.logger.info "payhero: router login trap on #{nas.ip_address}: #{msg}"
    else
      session.update!(connected: true, status: 'used', paid: true)
      voucher.update!(status: 'used', last_logged_in: Time.current, used_voucher: true, login_by: 'Voucher Code')
    end
  rescue => e
    Rails.logger.info "payhero: router login failed on #{nas&.ip_address}: #{e.message}"
  ensure
    client&.close
  end
end