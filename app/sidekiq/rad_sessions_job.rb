
# class RadSessionsJob
#   include Sidekiq::Job
#   queue_as :radacct
#   # sidekiq_options retry: false
  
#    def perform
#     Account.find_each do |account| # Iterate over all tenants
#       ActsAsTenant.with_tenant(account) do
#   threshold_time = 3.minutes.ago

#   online = 0
#   offline = 0

#   account.subscribers.find_each do |subscriber|
#     # Assume offline unless proven online
#     subscriber_online = false

#     subscriber.subscriptions.each do |subscription|
#       next unless subscription.ip_address.present?

#       if RadAcct.where(
#         acctstoptime: nil,
#         framedprotocol: 'PPP',
#         framedipaddress: subscription.ip_address
#       ).where('acctupdatetime > ?', threshold_time).exists?
#         subscriber_online = true
#         break
#       end
#     end





#     if subscriber_online
#       online += 1
#     else
#       offline += 1
#     end
#   end




#     active_sessions = RadAcct.where(
#     # framedprotocol: 'PPP',
#     acctstoptime: nil,

#   ).where('acctupdatetime > ?', 3.minutes.ago)


#   total_download = active_sessions.sum("COALESCE(acctinputoctets, 0)")
#   total_upload = active_sessions.sum("COALESCE(acctoutputoctets, 0)")
#   total_bytes  = total_download + total_upload

#   radacct_data = {
#     online_radacct: online,
#     offline_radacct: offline,
  
#     timestamp: Time.current
#   }


#   bandwidth_data = {
#      total_bandwidth: format_bytes(total_bytes),
#     total_download: format_bytes(total_download),
#     total_upload: format_bytes(total_upload),
#   }



#   active_sessions = RadAcct.where(acctstoptime: nil, framedprotocol: '').where('acctupdatetime > ?', 2.minutes.ago) 
#   active_sessions_upload_download = RadAcct.where(acctstoptime: nil, framedprotocol: '').where('acctupdatetime > ?', 3.minutes.ago) 


#   total_bytes = 0
#   total_bytes_upload_download = 0
#   total_bytes_upload = 0
#   total_bytes_download = 0



#   active_sessions_upload_download.map do |session|
#   download_bytes = session.acctinputoctets || 0
#   upload_bytes = session.acctoutputoctets || 0
#   total_bytes_download += download_bytes
#   total_bytes_upload += upload_bytes
#   session_total = download_bytes + upload_bytes
#   total_bytes_upload_download += session_total
# end



#   active_user_data = active_sessions.map do |session|
#     download_bytes = session.acctinputoctets || 0
#     upload_bytes = session.acctoutputoctets || 0
#     session_total = download_bytes + upload_bytes
#     total_bytes += session_total

#     {
#       username: session.username,
#       ip_address: session.framedipaddress.to_s,
#       mac_address: session.callingstationid,
#       up_time: format_uptime(session.acctsessiontime),
#       download: format_bytes(download_bytes),
#       upload: format_bytes(upload_bytes),
#       start_time: session.acctstarttime.strftime("%B %d, %Y at %I:%M %p"),
#       nas_port: session.nasportid,
#     }
#   end

# voucher_status = {
#       expired: HotspotVoucher.where(status: 'expired').count,
#       active: HotspotVoucher.where(status: 'active').count,
#       used: HotspotVoucher.where(status: 'used').count,
#     }


#   hotspot_data = {
#   active_user_count: active_user_data.size,
#   total_upload: format_bytes(total_bytes_upload),
#   total_download: format_bytes(total_bytes_download),
#   total_bandwidth: format_bytes(total_bytes_upload_download),
#   users: active_user_data
#   }

#   HotspotChannel.broadcast_to(account, 
#     hotspot_data
#   )


#     VoucherChannel.broadcast_to(account, voucher_status)
#   RadacctChannel.broadcast_to(account, radacct_data)
#   BandwidthChannel.broadcast_to(account, bandwidth_data)
# end
# end
# end



# def format_bytes(bytes)
#       units = ['B', 'KB', 'MB', 'GB', 'TB']
#       return '0 B' if bytes.zero?
    
#       exp = (Math.log(bytes) / Math.log(1024)).to_i
#       size = bytes / (1024.0**exp)
#       "%.2f #{units[exp]}" % size
    
    
#   end



# def router_uses_radius_payment(account_id)
#   setting = NasSetting.find_by(account_id: account_id)
#   setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
# end


#   def format_uptime(seconds)
#   return '0s' if seconds.nil?

#   mm, ss = seconds.divmod(60)
#   hh, mm = mm.divmod(60)
#   dd, hh = hh.divmod(24)

#   parts = []
#   parts << "#{dd}d" if dd > 0
#   parts << "#{hh}h" if hh > 0
#   parts << "#{mm}m" if mm > 0
#   parts << "#{ss}s"
#   parts.join(' ')
#     end
    
# end
# 

class RadSessionsJob
  include Sidekiq::Job
  queue_as :radacct
  require 'restclient'
  require 'json'

  def perform
    Account.find_each do |account|
      ActsAsTenant.with_tenant(account) do
        use_radius = router_uses_radius_payment(account.id)

        if use_radius
          process_radius_account(account)
        else
          process_native_account(account)
        end
      end
    end
  end

  private

  # ── Existing RadAcct-based path (unchanged logic, just extracted) ──
  def process_radius_account(account)
    threshold_time = 3.minutes.ago

    online = 0
    offline = 0

    account.subscribers.find_each do |subscriber|
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

      subscriber_online ? online += 1 : offline += 1
    end

    active_sessions = RadAcct.where(acctstoptime: nil)
                              .where('acctupdatetime > ?', 3.minutes.ago)

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
      total_upload: format_bytes(total_upload)
    }

    hotspot_sessions = RadAcct.where(acctstoptime: nil, framedprotocol: '')
                               .where('acctupdatetime > ?', 2.minutes.ago)
    hotspot_sessions_bw = RadAcct.where(acctstoptime: nil, framedprotocol: '')
                                  .where('acctupdatetime > ?', 3.minutes.ago)

    hs_total_bytes = 0
    hs_total_download = 0
    hs_total_upload = 0

    hotspot_sessions_bw.each do |session|
      download_bytes = session.acctinputoctets || 0
      upload_bytes = session.acctoutputoctets || 0
      hs_total_download += download_bytes
      hs_total_upload += upload_bytes
    end

    active_user_data = hotspot_sessions.map do |session|
      download_bytes = session.acctinputoctets || 0
      upload_bytes = session.acctoutputoctets || 0
      hs_total_bytes += (download_bytes + upload_bytes)

      {
        username: session.username,
        ip_address: session.framedipaddress.to_s,
        mac_address: session.callingstationid,
        up_time: format_uptime(session.acctsessiontime),
        download: format_bytes(download_bytes),
        upload: format_bytes(upload_bytes),
        start_time: session.acctstarttime&.strftime("%B %d, %Y at %I:%M %p"),
        nas_port: session.nasportid
      }
    end

    hotspot_data = {
      active_user_count: active_user_data.size,
      total_upload: format_bytes(hs_total_upload),
      total_download: format_bytes(hs_total_download),
      total_bandwidth: format_bytes(hs_total_bytes),
      users: active_user_data
    }

    broadcast_all(account, hotspot_data, radacct_data, bandwidth_data)
  end

  # ── New native MikroTik REST path (used when use_radius is false) ──
  def process_native_account(account)
    nas_routers = NasRouter.where(account_id: account.id)

    all_hotspot_users = []

    nas_routers.each do |nas|
      begin
        response = RestClient::Request.execute(
          method: :get,
          url: "http://#{nas.ip_address}/rest/ip/hotspot/active",
          user: nas.username,
          password: nas.password,
          timeout: 5,
          open_timeout: 3
        )

        users = JSON.parse(response.body)
        all_hotspot_users.concat(users) if users.is_a?(Array)

      rescue RestClient::Unauthorized
        Rails.logger.error "RadSessionsJob: REST auth failed for router #{nas.ip_address}"
        next
      rescue RestClient::Exceptions::Timeout, Errno::ETIMEDOUT
        Rails.logger.error "RadSessionsJob: Timed out reaching router #{nas.ip_address}"
        next
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
        Rails.logger.error "RadSessionsJob: Router #{nas.ip_address} unreachable: #{e.message}"
        next
      rescue StandardError => e
        Rails.logger.error "RadSessionsJob: Failed to fetch active sessions from #{nas.ip_address}: #{e.message}"
        next
      end
    end

    hs_total_download = 0
    hs_total_upload = 0

    active_user_data = all_hotspot_users.map do |user|
      download_bytes = user["bytes-in"].to_i
      upload_bytes   = user["bytes-out"].to_i
      hs_total_download += download_bytes
      hs_total_upload   += upload_bytes

      {
        username: user["user"],
        ip_address: user["address"],
        mac_address: user["mac-address"],
        up_time: user["uptime"],
        download: format_bytes(download_bytes),
        upload: format_bytes(upload_bytes),
        start_time: nil,
        nas_port: nil
      }
    end

    hs_total_bytes = hs_total_download + hs_total_upload

    hotspot_data = {
      active_user_count: active_user_data.size,
      total_upload: format_bytes(hs_total_upload),
      total_download: format_bytes(hs_total_download),
      total_bandwidth: format_bytes(hs_total_bytes),
      users: active_user_data
    }

    # PPPoE online/offline counts and overall bandwidth still rely on
    # RadAcct/PPP accounting elsewhere; native accounts have no PPP
    # session table equivalent here, so we report what we know (0/0)
    # rather than silently reusing radius numbers.
    radacct_data = {
      online_radacct: 0,
      offline_radacct: account.subscribers.count,
      timestamp: Time.current
    }

    bandwidth_data = {
      total_bandwidth: format_bytes(hs_total_bytes),
      total_download: format_bytes(hs_total_download),
      total_upload: format_bytes(hs_total_upload)
    }

    broadcast_all(account, hotspot_data, radacct_data, bandwidth_data)
  end

  def broadcast_all(account, hotspot_data, radacct_data, bandwidth_data)
    voucher_status = {
      expired: HotspotVoucher.where(account_id: account.id, status: 'expired').count,
      active: HotspotVoucher.where(account_id: account.id, status: 'active').count,
      used: HotspotVoucher.where(account_id: account.id, status: 'used').count
    }

    HotspotChannel.broadcast_to(account, hotspot_data)
    VoucherChannel.broadcast_to(account, voucher_status)
    RadacctChannel.broadcast_to(account, radacct_data)
    BandwidthChannel.broadcast_to(account, bandwidth_data)
  end

  def format_bytes(bytes)
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    return '0 B' if bytes.nil? || bytes.zero?

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

  def router_uses_radius_payment(account_id)
    setting = NasSetting.find_by(account_id: account_id)
    setting ? ActiveModel::Type::Boolean.new.cast(setting.use_radius) : true
  end
end