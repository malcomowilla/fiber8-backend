


class OnlineStatsBroadcastJob < ApplicationJob
  queue_as :default

  def perform
    Account.find_each do |tenant| # Iterate over all tenants
      ActsAsTenant.with_tenant(tenant) do
Rails.logger.info "Broadcasting online stats for #{tenant.subdomain}"
    active_sessions = RadAcct.where(
      acctstoptime: nil,
      framedprotocol: 'PPP',
      account_id: tenant.id
    ).where('acctupdatetime > ?', 3.minutes.ago)

    total_download = active_sessions.sum("COALESCE(acctinputoctets, 0)")
    total_upload   = active_sessions.sum("COALESCE(acctoutputoctets, 0)")

    ActionCable.server.broadcast("online_stats_channel", {
      active_user_count: active_sessions.count,
      download_total: total_download,
      upload_total: total_upload,
      timestamp: Time.current.strftime("%I:%M:%S %p")
    })
  end
end
end
end