# app/controllers/tuma_callbacks_controller.rb
class TumaCallbacksController < ApplicationController
  include HotspotVoucherProvisioning
  skip_before_action :verify_authenticity_token, raise: false

  def hotspot_callback
    session = ActsAsTenant.without_tenant { TemporarySession.find_by(session: params[:session_token]) }
    return head(:ok) unless session
    return head(:ok) if session.paid # idempotent — Tuma may retry the callback

    ActsAsTenant.with_tenant(Account.find_by(id: session.account_id)) { process_hotspot_callback(session) }
    head :ok
  end

  def device_binding_callback 
    session = ActsAsTenant.without_tenant { TemporarySession.find_by(session: params[:session_token]) }
    return head(:ok) unless session
    return head(:ok) if session.paid

    ActsAsTenant.with_tenant(Account.find_by(id: session.account_id)) { process_device_binding_callback(session) }
    head :ok
  end

  private

  def process_hotspot_callback(session)
    data = JSON.parse(request.body.read) rescue {}
    return if data['result_code'].to_s != '0'

    hotspot_package = HotspotPackage.find_by(name: session.hotspot_package, account_id: session.account_id)
    return unless hotspot_package

    voucher = HotspotVoucher.create!(
      package: session.hotspot_package, phone: session.phone_number, voucher: session.voucher_code,
      mac: session.mac, ip: session.ip, checkout_request_id: data['checkout_request_id'],
      account_id: session.account_id, hotspot_package_id: hotspot_package.id, status: 'active'
    )
    session.update!(hotspot_voucher_id: voucher.id)

    HotspotMpesaRevenue.create!(
      amount: data['amount'], voucher: voucher.voucher, reference: data['mpesa_receipt_number'],
      payment_method: 'Tuma', time_paid: data['timestamp'], account_id: session.account_id,
      phone_number: session.phone_number, status: 'Completed', hotspot_voucher_id: voucher.id
    )

    provision_voucher(hotspot_package, voucher, session.account_id)

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
        voucher.update!(status: 'used', last_logged_in: Time.current, used_voucher: true, login_by: 'Tuma STK')
      end
    rescue => e
      Rails.logger.warn "Tuma hotspot callback: router login failed: #{e.message}"
    end
  end

  def process_device_binding_callback(session)
    data = JSON.parse(request.body.read) rescue {}
    return if data['result_code'].to_s != '0'

    tv_plan = TvPlan.find_by(id: session.tv_plan_id, account_id: session.account_id)
    return unless tv_plan

    nas = NasRouter.find_by(id: tv_plan.nas_router_id, account_id: tv_plan.account_id)

    binding = IpBinding.create!(
      name: session.device_name, mac: session.device_mac, package: tv_plan.name, ip: session.ip,
      tv_plan_id: tv_plan.id, phone: session.phone_number, source: 'tv_plan_purchase', status: 'active',
      device_type: session.device_type, account_id: session.account_id, router_id: nas&.id,
      expiry: tv_plan_expiration(tv_plan)
    )

    HotspotMpesaRevenue.create!(
      amount: data['amount'], voucher: "DEVICE-#{binding.mac}", reference: data['mpesa_receipt_number'],
      payment_method: 'Tuma', time_paid: data['timestamp'], account_id: session.account_id,
      phone_number: session.phone_number, status: 'Completed'
    )

    if nas
      begin
        mikrotik_add_binding_direct(binding, nas)
        mikrotik_add_queue_for_tv_plan(binding, tv_plan, nas)
      rescue => e
        Rails.logger.error "Tuma device_binding callback: MikroTik failed: #{e.message}"
      end
    end

    session.update!(connected: true, status: 'used', paid: true)
  end

  def tv_plan_expiration(tv_plan)
    seconds = case tv_plan.validity_period_units.to_s.downcase
              when 'minutes' then tv_plan.validity.to_i.minutes
              when 'hours' then tv_plan.validity.to_i.hours
              when 'days' then tv_plan.validity.to_i.days
              else 0.seconds
              end
    (Time.current + seconds).strftime('%Y-%m-%d %H:%M:%S')
  end

  def mikrotik_add_binding_direct(binding, nas)
    require 'net/ssh'
    mac = binding.mac.upcase.gsub('-', ':')
    cmd = "/ip hotspot ip-binding add mac-address=\"#{mac}\" type=bypassed server=hotspot1"
    cmd += " comment=\"#{binding.name}\"" if binding.name.present?
    Net::SSH.start(nas.ip_address, nas.username, password: nas.password.to_s,
      verify_host_key: :never, non_interactive: true, timeout: 15) { |ssh| ssh.exec!(cmd) }
  end

  def mikrotik_add_queue_for_tv_plan(binding, tv_plan, nas)
    return unless binding.ip.present? && tv_plan&.upload_limit.present?
    require 'net/ssh'
    queue_name = "binding_#{binding.mac.upcase.gsub(':', '')}"
    cmd = "/queue simple add name=\"#{queue_name}\" target=\"#{binding.ip}\" " \
          "max-limit=\"#{tv_plan.upload_limit}M/#{tv_plan.download_limit}M\" comment=\"tv_plan_#{binding.id}\""
    Net::SSH.start(nas.ip_address, nas.username, password: nas.password.to_s,
      verify_host_key: :never, non_interactive: true, timeout: 15) { |ssh| ssh.exec!(cmd) }
  end
end