class SyncIpPoolJob < ApplicationJob
  queue_as :default

  def perform(ip_pool_id)
    ip_pool = IpPool.find_by(id: ip_pool_id)
    return unless ip_pool

    MikrotikPoolSyncService.sync(ip_pool)
  rescue MikrotikPoolSyncService::SyncError => e
    Rails.logger.error("[SyncIpPoolJob] pool=#{ip_pool_id} #{e.message}")
  end
end