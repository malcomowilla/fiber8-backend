class DeleteSessionJob
  include Sidekiq::Job

  sidekiq_options queue: :default, lock: :until_executed, lock_timeout: 0

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        sync_sessions!
      end
    end
  end

  private

  def sync_sessions!
    # 1️⃣ Get ONLINE IPs from RADIUS
    online_ips = RadAcct
      .where(acctstoptime: nil)
      .where(framedprotocol: [nil, ''])
      .where.not(framedipaddress: [nil, ''])
      .pluck(:framedipaddress)
      .uniq

    # 2️⃣ Mark ONLINE sessions
    TemporarySession
      .where(ip: online_ips)
      .where(connected: false)
      .update_all(connected: true, updated_at: Time.current)

    # 3️⃣ Mark OFFLINE sessions
    TemporarySession
      .where.not(ip: online_ips)
      .where(connected: true)
      .update_all(connected: false, updated_at: Time.current)

    # 4️⃣ (Optional) Cleanup old offline sessions
    # TemporarySession
    #   .where(connected: false)
    #   .where('updated_at < ?', 10.minutes.ago)
    #   .delete_all
  end
end
