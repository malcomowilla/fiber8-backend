# app/controllers/paystack_callbacks_controller.rb
class PaystackCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def hotspot_callback
    payload = request.raw_post
    Rails.logger.info "========== PAYSTACK WEBHOOK RECEIVED =========="
    Rails.logger.info payload

    event = JSON.parse(payload) rescue nil
    return head :bad_request unless event

    reference = event.dig('data', 'reference')
    account = account_for_reference(reference)

    unless account && valid_signature?(payload, account)
      Rails.logger.warn "Invalid Paystack signature (reference=#{reference.inspect}, account=#{account&.id.inspect})"
      return head :unauthorized
    end

    ActsAsTenant.with_tenant(account) do
      case event['event']
      when 'charge.success'
        process_success(event, reference)
      when 'charge.failed'
        process_failure(reference, event.dig('data', 'gateway_response'))
      else
        Rails.logger.info "Paystack event #{event['event']} ignored for reference #{reference}"
      end
    end

    head :ok
  rescue => e
    Rails.logger.error "Paystack webhook error: #{e.message}\n#{e.backtrace.take(10).join("\n")}"
    # ack anyway once we've gotten this far — avoids Paystack retry-storming
    # a webhook that failed on our side after signature already checked out
    head :ok
  end

  private

  # Paystack's webhook has no tenant header, so we resolve the account from
  # the pending record HotspotVouchersController#make_payment already
  # created for this reference — *before* we trust anything else about the
  # request. unscoped because these lookups happen outside any tenant scope.
  def account_for_reference(reference)
    return nil if reference.blank?
    revenue = HotspotMpesaRevenue.unscoped.find_by(checkout_request_id: reference)
    account_id = revenue&.account_id
    account_id ||= TemporarySession.unscoped.find_by(checkout_request_id: reference)&.account_id
    return nil unless account_id
    ActsAsTenant.without_tenant { Account.find_by(id: account_id) }
  end

  def valid_signature?(payload, account)
    setting = ActsAsTenant.without_tenant { PaystackSetting.find_by(account_id: account.id) }
    return false unless setting&.secret_key.present?

    signature = request.headers['HTTP_X_PAYSTACK_SIGNATURE']
    return false if signature.blank?

    expected = OpenSSL::HMAC.hexdigest('sha512', setting.secret_key, payload)
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end


def process_success(event, reference)
  revenue = HotspotMpesaRevenue.find_by(checkout_request_id: reference)
  return Rails.logger.warn("Paystack success for unknown reference #{reference}") unless revenue
  return if revenue.status == 'Completed' # webhook can be delivered more than once

  setting = ActsAsTenant.without_tenant { PaystackSetting.find_by(account_id: revenue.account_id) }
  unless setting&.secret_key.present?
    Rails.logger.warn "Paystack success: no secret key configured for account #{revenue.account_id}"
    return
  end

  verified = verify_transaction(reference, setting.secret_key)
  unless verified
    Rails.logger.warn "Paystack verify failed or returned non-success for reference #{reference}"
    return
  end

  receipt_number = verified['receipt_number'].presence || verified['reference']

  revenue.update!(status: 'Completed', time_paid: Time.current, reference: receipt_number)

  session = TemporarySession.find_by(checkout_request_id: reference)
  return unless session

  hotspot_package = HotspotPackage.find_by(name: session.hotspot_package, account_id: session.account_id)
  unless hotspot_package
    Rails.logger.warn "Paystack success: package '#{session.hotspot_package}' not found for account #{session.account_id}"
    return
  end

  voucher = HotspotVoucher.find_or_create_by!(voucher: session.voucher_code) do |v|
    v.package = session.hotspot_package
    v.phone = session.phone_number
    v.mac = session.mac
    v.ip = session.ip
    v.checkout_request_id = reference
    v.account_id = session.account_id
    v.hotspot_package_id = hotspot_package.id
    v.status = 'active'
  end
  session.update!(hotspot_voucher_id: voucher.id)
  revenue.update!(hotspot_voucher_id: voucher.id)

  provision_voucher(hotspot_package, voucher, session)

  begin
    SendSmsHotspotService.send_sms(voucher.voucher, event['data'], reference)
  rescue => e
    Rails.logger.warn "Paystack success: SMS send failed: #{e.message}"
  end

  login_on_router(hotspot_package, voucher, session)
end


# Calls GET /transaction/verify/:reference and returns the `data` hash only
# when Paystack confirms status == 'success'. Returns nil on any failure so
# callers never act on an unverified/forged webhook body.
def verify_transaction(reference, secret_key)
  uri = URI("https://api.paystack.co/transaction/verify/#{URI.encode_www_form_component(reference)}")

  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{secret_key}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 10, open_timeout: 5) do |http|
    http.request(request)
  end

  unless response.is_a?(Net::HTTPSuccess)
    Rails.logger.warn "Paystack verify HTTP error for #{reference}: #{response.code} #{response.body}"
    return nil
  end

  body = JSON.parse(response.body)
  return nil unless body['status'] == true && body.dig('data', 'status') == 'success'

  body['data']
rescue => e
  Rails.logger.warn "Paystack verify request failed for #{reference}: #{e.message}"
  nil
end








  def process_failure(reference, gateway_response)
    revenue = HotspotMpesaRevenue.find_by(checkout_request_id: reference)
    return unless revenue
    revenue.update!(status: 'Cancelled')
    Rails.logger.info "Paystack payment #{reference} failed: #{gateway_response}"
  end

  # Mirrors the branching in HotspotVouchersController#check_payment_status
  # for the M-Pesa hotspot_ path — radius (real-time vs accumulated) or
  # native MikroTik sync. Kept self-contained here rather than reaching into
  # HotspotVouchersController's private methods, since this runs from a
  # webhook with no request/params context.
  def provision_voucher(hotspot_package, voucher, session)
    expiration_time = compute_expiration(hotspot_package)
    voucher.update(expiration: expiration_time&.strftime("%B %d, %Y at %I:%M %p")) if expiration_time

    voucher_expiration = HotspotSetting.find_by(account_id: session.account_id)&.voucher_expiration

    if router_uses_radius?(session.account_id)
      if voucher_expiration == 'Real-time expiration'
        create_voucher_radcheck(voucher, hotspot_package, session.account_id, expiration_time)
      else
        create_voucher_radcheck_accumulated_sessions(voucher, hotspot_package, session.account_id, expiration_time)
      end
    else
      # Native MikroTik account — the router has no idea this voucher
      # exists until we PUT it. This is the step that was missing before:
      # login_on_router would hit a router with no matching hotspot user.
      if voucher_expiration == 'Real-time expiration'
        sync_voucher_natively(voucher)
      else
        sync_voucher_natively_realtime_expiration(voucher)
      end
    end
  end

  def compute_expiration(hotspot_package)
    return nil unless hotspot_package.validity.present? && hotspot_package.validity_period_units.present?
    case hotspot_package.validity_period_units.downcase
    when 'days'    then Time.current + hotspot_package.validity.days
    when 'hours'   then Time.current + hotspot_package.validity.hours
    when 'minutes' then Time.current + hotspot_package.validity.minutes
    end
  end

  def create_voucher_radcheck(voucher, hotspot_package, account_id, expiration_time)
    group_name = "hotspot_#{account_id}_#{hotspot_package.name.parameterize(separator: '_')}"

    radcheck = RadCheck.find_or_initialize_by(
      username: voucher.voucher, account_id: account_id, radiusattribute: 'Cleartext-Password'
    )
    radcheck.update!(op: ':=', value: voucher.voucher)

    rad_user_group = RadUserGroup.find_or_initialize_by(
      username: voucher.voucher, groupname: group_name, priority: 1, account_id: account_id
    )
    rad_user_group.update!(username: voucher.voucher, groupname: group_name, priority: 1)

    return unless expiration_time

    exp_check = RadCheck.find_or_initialize_by(
      username: voucher.voucher, account_id: account_id, radiusattribute: 'Expiration'
    )
    exp_check.update!(op: ':=', value: expiration_time.strftime("%d %b %Y %H:%M:%S"))
  end

  def create_voucher_radcheck_accumulated_sessions(voucher, hotspot_package, account_id, expiration_time)
    group_name = "hotspot_#{account_id}_#{hotspot_package.name.parameterize(separator: '_')}"

    radcheck = RadCheck.find_or_initialize_by(
      username: voucher.voucher, account_id: account_id, radiusattribute: 'Cleartext-Password'
    )
    radcheck.update!(op: ':=', value: voucher.voucher)

    rad_user_group = RadUserGroup.find_or_initialize_by(
      username: voucher.voucher, groupname: group_name, priority: 1, account_id: account_id
    )
    rad_user_group.update!(username: voucher.voucher, groupname: group_name, priority: 1)

    return unless hotspot_package.validity.present? && hotspot_package.validity_period_units.present?

    seconds = case hotspot_package.validity_period_units.downcase
              when 'minutes' then hotspot_package.validity.minutes.to_i
              when 'hours'   then hotspot_package.validity.hours.to_i
              when 'days'    then hotspot_package.validity.days.to_i
              end
    return unless seconds

    max_session = RadCheck.find_or_initialize_by(
      username: voucher.voucher, account_id: account_id, radiusattribute: 'Max-All-Session'
    )
    max_session.update!(op: ':=', value: seconds)
  end






  def sync_voucher_natively(voucher)
  package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
  return voucher.update(sync_status: 'failed', sync_error: 'Package not found') unless package

  nas = NasRouter.find_by(name: package.nas_router, account_id: voucher.account_id)
  return voucher.update(sync_status: 'failed', sync_error: 'No router specified or router not found') unless nas

  client = RouterosApiClient.new(nas.ip_address, nas.username.to_s, nas.password.to_s, timeout: 10)
  client.connect

  existing = client.talk(['/ip/hotspot/user/print', "?name=#{voucher.voucher}"])
  existing_sentence = existing.find { |s| s.first == '!re' }
  existing_id = existing_sentence&.find { |w| w.start_with?('=.id=') }&.sub('=.id=', '')

  attrs = [
    "=name=#{voucher.voucher}",
    "=password=#{voucher.voucher}",
    "=profile=#{package.name}"
  ]

  reply =
    if existing_id
      client.talk(['/ip/hotspot/user/set', "=.id=#{existing_id}"] + attrs)
    else
      client.talk(['/ip/hotspot/user/add'] + attrs)
    end

  if reply.last.first == '!trap'
    error_message = reply.last.find { |w| w.start_with?('=message=') }&.sub('=message=', '') || 'Unknown MikroTik error'
    voucher.update(sync_status: 'failed', sync_error: error_message)
  else
    voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)
  end

rescue RouterosApiClient::ApiError => e
  voucher.update(sync_status: 'failed', sync_error: e.message)
rescue Errno::ETIMEDOUT, IO::TimeoutError
  voucher.update(sync_status: 'failed', sync_error: "Router #{nas.ip_address} timed out")
rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
  voucher.update(sync_status: 'failed', sync_error: "Router unreachable: #{e.message}")
rescue => e
  voucher.update(sync_status: 'failed', sync_error: e.message)
ensure
  client&.close
end

def sync_voucher_natively_realtime_expiration(voucher)
  package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
  return voucher.update(sync_status: 'failed', sync_error: 'Package not found') unless package

  nas = NasRouter.find_by(name: package.nas_router, account_id: voucher.account_id)
  return voucher.update(sync_status: 'failed', sync_error: 'No router specified or router not found') unless nas

  client = RouterosApiClient.new(nas.ip_address, nas.username.to_s, nas.password.to_s, timeout: 10)
  client.connect

  existing = client.talk(['/ip/hotspot/user/print', "?name=#{voucher.voucher}"])
  existing_sentence = existing.find { |s| s.first == '!re' }
  existing_id = existing_sentence&.find { |w| w.start_with?('=.id=') }&.sub('=.id=', '')

  attrs = [
    "=name=#{voucher.voucher}",
    "=password=#{voucher.voucher}",
    "=profile=#{package.name}",
    "=limit-uptime=#{validity_for_mikrotik(package)}"
  ]

  reply =
    if existing_id
      client.talk(['/ip/hotspot/user/set', "=.id=#{existing_id}"] + attrs)
    else
      client.talk(['/ip/hotspot/user/add'] + attrs)
    end

  if reply.last.first == '!trap'
    error_message = reply.last.find { |w| w.start_with?('=message=') }&.sub('=message=', '') || 'Unknown MikroTik error'
    voucher.update(sync_status: 'failed', sync_error: error_message)
  else
    voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)
  end

rescue RouterosApiClient::ApiError => e
  voucher.update(sync_status: 'failed', sync_error: e.message)
rescue Errno::ETIMEDOUT, IO::TimeoutError
  voucher.update(sync_status: 'failed', sync_error: "Router #{nas.ip_address} timed out")
rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
  voucher.update(sync_status: 'failed', sync_error: "Router unreachable: #{e.message}")
rescue => e
  voucher.update(sync_status: 'failed', sync_error: e.message)
ensure
  client&.close
end

  
  def validity_for_mikrotik(pkg)
    case pkg.validity_period_units
    when "minutes" then "#{pkg.validity}m"
    when "hours"   then "#{pkg.validity}h"
    when "days"    then "#{pkg.validity}d"
    when "weeks"   then "#{pkg.validity}w"
    else "0s"
    end
  end

  def mikrotik_error_message(e)
    return e.message unless e.response
    body = e.response.body.to_s
    parsed = JSON.parse(body) rescue nil
    return body.presence || e.message unless parsed
    parsed['detail'] || parsed['message'] || parsed['error'] || body
  end

  def router_uses_radius?(account_id)
    setting = NasSetting.find_by(account_id: account_id)
    setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
  end

  def login_on_router(hotspot_package, voucher, session)
  nas_router = NasRouter.find_by(name: hotspot_package.nas_router, account_id: session.account_id)
  unless nas_router
    Rails.logger.warn "Paystack success: no router found for account #{session.account_id}"
    return
  end

  client = nil
  begin
    client = RouterosApiClient.new(nas_router.ip_address, nas_router.username.to_s, nas_router.password.to_s, timeout: 5)
    client.connect

    reply = client.talk([
      '/ip/hotspot/active/login',
      "=ip=#{session.ip}",
      "=user=#{voucher.voucher}",
      "=password=#{voucher.voucher}"
    ])

    if reply.last.first == '!trap'
      error_message = reply.last.find { |w| w.start_with?('=message=') }&.sub('=message=', '') || 'Unknown MikroTik error'
      Rails.logger.warn "Paystack success: MikroTik API error: #{error_message}"
    else
      session.update!(connected: true, status: 'used', paid: true)
      voucher.update!(status: 'used', last_logged_in: Time.current, used_voucher: true, login_by: 'Paystack')
    end

  rescue RouterosApiClient::ApiError => e
    Rails.logger.warn "Paystack success: RouterOS API error: #{e.message}"
  rescue Errno::ETIMEDOUT, IO::TimeoutError
    Rails.logger.warn "Paystack success: router #{nas_router.ip_address} timed out"
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    Rails.logger.warn "Paystack success: router unreachable: #{e.message}"
  rescue => e
    Rails.logger.warn "Paystack success: router login failed: #{e.message}"
  ensure
    client&.close
  end
end





end