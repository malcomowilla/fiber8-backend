class VoucherSyncJob < ApplicationJob
  # include Sidekiq::Job
  self.queue_adapter = :solid_queue
  queue_as :default

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        begin
          # RADIUS accounts don't rely on this native-sync flow at all —
          # RadCheck/RadUserGroup rows are created directly, so skip them.
          next if router_uses_radius?(tenant)

          vouchers_to_sync = HotspotVoucher
            .where(account_id: tenant.id)
            .where(sync_status: ['not_synced', 'failed', nil])
            .where(status: 'active')

          next if vouchers_to_sync.none?

          Rails.logger.info "VoucherSyncJob: found #{vouchers_to_sync.count} unsynced voucher(s) for tenant #{tenant.id}"

          vouchers_to_sync.find_each do |voucher|
            sync_voucher(voucher, tenant)
          end

        rescue => e
          Rails.logger.error "VoucherSyncJob failed for tenant #{tenant.id}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end
    end
  end

  private

  def router_uses_radius?(tenant)
    setting = NasSetting.find_by(account_id: tenant.id)
    setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
  end

  def sync_voucher(voucher, tenant)
    package = HotspotPackage.find_by(name: voucher.package, account_id: voucher.account_id)
    unless package
      voucher.update(sync_status: 'failed', sync_error: 'Package not found')
      return
    end

    nas = NasRouter.find_by(name: package.nas_router, account_id: voucher.account_id)
    unless nas
      voucher.update(sync_status: 'failed', sync_error: 'No router specified or router not found')
      return
    end

    voucher_expiration_setting = HotspotSetting.find_by(account_id: tenant.id)&.voucher_expiration

    payload = { name: voucher.voucher, password: voucher.voucher, profile: package.name }

    # mirror sync_voucher_natively_realtime_expiration: only attach an
    # uptime limit when the account is NOT using real-time expiration
    if voucher_expiration_setting.present? && voucher_expiration_setting != 'Real-time expiration'
      payload["limit-uptime"] = validity_for_mikrotik(package)
    end

    RestClient::Request.execute(
      method: :put,
      url: "http://#{nas.ip_address}/rest/ip/hotspot/user",
      user: nas.username.to_s,
      password: nas.password.to_s,
      payload: payload.to_json,
      headers: { content_type: :json },
      timeout: 10,
      open_timeout: 5
    )

    voucher.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)
    Rails.logger.info "VoucherSyncJob: synced voucher #{voucher.voucher} (tenant #{tenant.id}, router #{nas.ip_address})"

  rescue RestClient::Unauthorized
    voucher.update(sync_status: 'failed', sync_error: 'Router authentication failed')

  rescue RestClient::ExceptionWithResponse => e
    voucher.update(sync_status: 'failed', sync_error: "MikroTik error: #{e.response}")

  rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
    voucher.update(sync_status: 'failed', sync_error: "Router #{nas.ip_address} timed out")

  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    voucher.update(sync_status: 'failed', sync_error: "Router unreachable: #{e.message}")

  rescue => e
    voucher.update(sync_status: 'failed', sync_error: e.message)
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
end