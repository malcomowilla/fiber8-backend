class DeleteSessionJob
 include Sidekiq::Job
  queue_as :default

  sidekiq_options lock: :until_executed, lock_timeout: 0


  def perform
    Rails.logger.info "[DeleteSessionJob] START"

    # Account.find_each do |tenant|
    #   # ActsAsTenant.with_tenant(tenant) do
    #   #   Rails.logger.info "[DeleteSessionJob] Processing tenant #{tenant.id}"
    #   #   sync_sessions!
    #   # end
    # end
sync_sessions
    Rails.logger.info "[DeleteSessionJob] FINISH"
  rescue => e
    Rails.logger.info "[DeleteSessionJob] ERROR: #{e.message}"
    Rails.logger.info e.backtrace.join("\n")
    raise e
  end

  private

  def sync_sessions
    Rails.logger.info "[DeleteSessionJob] Sync sessions started"

    online_ips = RadAcct.where(acctstoptime: nil, framedprotocol: '').where('acctupdatetime > ?', 3.minutes.ago).pluck(:framedipaddress).uniq.map(&:to_s)
      

   

      offline_ips = RadAcct.where.not(acctstoptime: nil, framedprotocol: '').where.not('acctupdatetime > ?', 3.minutes.ago).pluck(:framedipaddress).uniq.map(&:to_s)
      
      

    Rails.logger.info "[DeleteSessionJob] Online IPs: #{online_ips.inspect}"

    updated_online = TemporarySession
      .where(ip:  online_ips)
      # .where(connected: true)
      .update_all(connected: true, updated_at: Time.current)

    Rails.logger.info "[DeleteSessionJob] Marked ONLINE: #{updated_online}"

    updated_offline = TemporarySession
      .where(ip: offline_ips)
      #  .where(connected: false)
      .update_all(connected: false, updated_at: Time.current)

    Rails.logger.info "[DeleteSessionJob] Marked OFFLINE: #{updated_offline}"
  end
end
