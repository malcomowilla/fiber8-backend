


class RadSessionsJob
  include Sidekiq::Job
  queue_as :radacct
  # sidekiq_options retry: false
  
   def perform
    Account.find_each do |account| # Iterate over all tenants
      ActsAsTenant.with_tenant(account) do
  threshold_time = 3.minutes.ago

  online = 0
  offline = 0

  account.subscribers.find_each do |subscriber|
    # Assume offline unless proven online
    subscriber_online = false

    subscriber.subscriptions.each do |subscription|
      next unless subscription.ip_address.present?

      if RadAcct.where(
        acctstoptime: nil,
        framedprotocol: 'PPP',
        framedipaddress: subscription.ip_address
      ).where('acctupdatetime > ?', threshold_time).exists?
        subscriber_online = true
        break
      end
    end





    if subscriber_online
      online += 1
    else
      offline += 1
    end
  end




    active_sessions = RadAcct.where(
    framedprotocol: 'PPP'
  )


  total_download = active_sessions.sum("COALESCE(acctinputoctets, 0)")
  total_upload   = active_sessions.sum("COALESCE(acctoutputoctets, 0)")
  total_bytes    = total_download + total_upload

  radacct_data = {
    online_radacct: online,
    offline_radacct: offline,
  
    timestamp: Time.current
  }



  bandwidth_data = {
     total_bandwidth: format_bytes(total_bytes),
    total_download: format_bytes(total_download),
    total_upload: format_bytes(total_upload),
  }



  active_sessions = RadAcct.where(acctstoptime: nil, framedprotocol: '').where('acctupdatetime > ?', 3.minutes.ago) 
  active_sessions_upload_download = RadAcct.where(framedprotocol: '')

  total_bytes = 0
  total_bytes_upload_download = 0
  total_bytes_upload = 0
  total_bytes_download = 0



 active_user_data_upload_download = active_sessions_upload_download.map do |session|
  download_bytes = session.acctinputoctets || 0
  upload_bytes = session.acctoutputoctets || 0
  total_bytes_download += download_bytes
  total_bytes_upload += upload_bytes
  session_total = download_bytes + upload_bytes
  total_bytes_upload_download += session_total
end



  active_user_data = active_sessions.map do |session|
    download_bytes = session.acctinputoctets || 0
    upload_bytes = session.acctoutputoctets || 0
    session_total = download_bytes + upload_bytes
    total_bytes += session_total

    {
      username: session.username,
      ip_address: session.framedipaddress.to_s,
      mac_address: session.callingstationid,
      up_time: format_uptime(session.acctsessiontime),
      download: format_bytes(download_bytes),
      upload: format_bytes(upload_bytes),
      start_time: session.acctstarttime.strftime("%B %d, %Y at %I:%M %p"),
      nas_port: session.nasportid
    }
  end



  hotspot_data = {
active_user_count: active_user_data.size,
  total_upload: format_bytes(total_bytes_upload),
  total_download: format_bytes(total_bytes_download),
  total_bandwidth: format_bytes(total_bytes_upload_download),
  users: active_user_data
  }

  HotspotChannel.broadcast_to(account, 
    hotspot_data
  )


  RadacctChannel.broadcast_to(account, radacct_data)
  BandwidthChannel.broadcast_to(account, bandwidth_data)
end
end
end



def format_bytes(bytes)
      units = ['B', 'KB', 'MB', 'GB', 'TB']
      return '0 B' if bytes.zero?
    
      exp = (Math.log(bytes) / Math.log(1024)).to_i
      size = bytes / (1024.0**exp)
      "%.2f #{units[exp]}" % size
    
    
  end




  def format_uptime(seconds)
  return '0s' if seconds.nil?

  mm, ss = seconds.divmod(60)
  hh, mm = mm.divmod(60)
  dd, hh = hh.divmod(24)

  parts = []
  parts << "#{dd}d" if dd > 0
  parts << "#{hh}h" if hh > 0
  parts << "#{mm}m" if mm > 0
  parts << "#{ss}s"
  parts.join(' ')
    end
    
end