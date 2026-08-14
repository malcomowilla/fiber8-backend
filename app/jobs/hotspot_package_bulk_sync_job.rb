class HotspotPackageBulkSyncJob < ApplicationJob
  # include Sidekiq::Job
  queue_as :default

  def perform(account_id, package_ids)
    tenant = Account.find_by(id: account_id)
    return unless tenant

    ActsAsTenant.with_tenant(tenant) do
      HotspotPackage.where(id: package_ids, account_id: tenant.id).find_each do |pkg|
        sync_package(pkg)
      end
    end

    Rails.logger.info "HotspotPackageBulkSyncJob: finished #{package_ids.size} package(s) for tenant #{account_id}"
  rescue => e
    Rails.logger.error "HotspotPackageBulkSyncJob failed for tenant #{account_id}: #{e.message}"
  end

  private

  def sync_package(pkg)
    nas = NasRouter.find_by(name: pkg.nas_router, account_id: pkg.account_id)
    return pkg.update(sync_status: 'failed', sync_error: 'No router assigned') unless nas

    session_timeout = validity_in_seconds(pkg)
    rate_limit = "#{pkg.upload_limit}M/#{pkg.download_limit}M"

    RestClient::Request.execute(
      method: :put,
      url: "http://#{nas.ip_address}/rest/ip/hotspot/user/profile",
      user: nas.username, password: nas.password,
      payload: {
        name: pkg.name,
        "rate-limit": rate_limit,
        "session-timeout": session_timeout.to_s,
        "shared-users": pkg.shared_users.to_s
      }.to_json,
      headers: { content_type: :json },
      timeout: 10,
      open_timeout: 5
    )

    pkg.update(sync_status: 'synced', synced_at: Time.current, sync_error: nil)

  rescue RestClient::ExceptionWithResponse => e
    pkg.update(sync_status: 'failed', sync_error: mikrotik_error_message(e))
  rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
    pkg.update(sync_status: 'failed', sync_error: "Router #{nas&.ip_address} timed out")
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    pkg.update(sync_status: 'failed', sync_error: "Router unreachable: #{e.message}")
  rescue => e
    pkg.update(sync_status: 'failed', sync_error: e.message)
  end

  def validity_in_seconds(pkg)
    case pkg.validity_period_units
    when 'days' then pkg.validity.to_i.days.to_i
    when 'hours' then pkg.validity.to_i.hours.to_i
    when 'minutes' then pkg.validity.to_i.minutes.to_i
    else 0
    end
  end

  # Pulls MikroTik's real error text out of the response body instead of
  # leaving you with a bare "400 Bad Request".
  def mikrotik_error_message(e)
    return e.message unless e.response
    body = e.response.body.to_s
    parsed = JSON.parse(body) rescue nil
    return body.presence || e.message unless parsed
    parsed['detail'] || parsed['message'] || parsed['error'] || body
  end
end