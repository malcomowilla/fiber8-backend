


class OnlineStatsBroadcastJob 
  include Sidekiq::Job
  queue_as :default

  def perform
    Rails.logger.info "Broadcasting online stats "

    
Rails.logger.info "Broadcasting online stats for"
    active_sessions = RadAcct.where(
      acctstoptime: nil,
      framedprotocol: 'PPP',
    ).where('acctupdatetime > ?', 3.minutes.ago)

    total_download = active_sessions.sum("COALESCE(acctinputoctets, 0)")
    total_upload   = active_sessions.sum("COALESCE(acctoutputoctets, 0)")

    ActionCable.server.broadcast("online_stats_channel",content: 'hello test')
  end
end
