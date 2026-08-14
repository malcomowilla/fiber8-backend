# app/jobs/hotspot_voucher_bulk_sync_job.rb
class HotspotVoucherBulkSyncJob < ApplicationJob
  # include Sidekiq::Job
  queue_as :default

  def perform(account_id, voucher_ids)
    tenant = Account.find_by(id: account_id)
    return unless tenant

    ActsAsTenant.with_tenant(tenant) do
      expiration_setting = HotspotSetting.find_by(account_id: tenant.id)&.voucher_expiration

      HotspotVoucher.where(id: voucher_ids, account_id: tenant.id).find_each do |voucher|
        sync_voucher(voucher, expiration_setting)
      end
    end

    Rails.logger.info "HotspotVoucherBulkSyncJob: finished #{voucher_ids.size} voucher(s) for tenant #{account_id}"
  rescue => e
    Rails.logger.error "HotspotVoucherBulkSyncJob failed for tenant #{account_id}: #{e.message}"
  end

  private

  def sync_voucher(voucher, expiration_setting)
    package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
    return voucher.update(sync_status: 'failed', sync_error: 'Package not found') unless package

    nas = NasRouter.find_by(name: package.nas_router, account_id: voucher.account_id)
    return voucher.update(sync_status: 'failed', sync_error: 'No router specified or router not found') unless nas

    payload = { name: voucher.voucher, password: voucher.voucher, profile: package.name }
    if expiration_setting.present? && expiration_setting != 'Real-time expiration'
      payload["limit-uptime"] = validity_for_mikrotik(package)
    end

    RestClient::Request.execute(
      method: :put,
      url: "http://#{nas.ip_address}/rest/ip/hotspot/user",
      user: nas.username.to_s, password: nas.password.to_s,
      payload: payload.to_json,
      headers: { content_type: :json },
      timeout: 10,
      open_timeout: 5
    )

    voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)

  rescue RestClient::ExceptionWithResponse => e
    voucher.update(sync_status: 'failed', sync_error: mikrotik_error_message(e))
  rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
    voucher.update(sync_status: 'failed', sync_error: "Router #{nas&.ip_address} timed out")
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    voucher.update(sync_status: 'failed', sync_error: "Router unreachable: #{e.message}")
  rescue => e
    voucher.update(sync_status: 'failed', sync_error: e.message)
  end

  def validity_for_mikrotik(pkg)
    case pkg.validity_period_units
    when "minutes" then "#{pkg.validity}m"
    when "hours" then "#{pkg.validity}h"
    when "days" then "#{pkg.validity}d"
    when "weeks" then "#{pkg.validity}w"
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
end