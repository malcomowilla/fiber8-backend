class DeleteSessionJob
 include Sidekiq::Job
  queue_as :default

  sidekiq_options lock: :until_executed, lock_timeout: 0


  def perform
    Rails.logger.info "[Deletemacjob] START"

    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
    #   #   Rails.logger.info "[DeleteSessionJob] Processing tenant #{tenant.id}"
    #   #   sync_sessions!
    #   # end
    # end
sync_sessions(tenant)

      end
    end


    Rails.logger.info "[Deletemacjob] FINISH"
  rescue => e
    Rails.logger.info "[Deletemacjob] ERROR: #{e.message}"
    Rails.logger.info e.backtrace.join("\n")
    raise e
  end

  private

  def sync_sessions(tenant)
    Rails.logger.info "[Deletemacjob] Sync sessions started"

    # online_ips = RadAcct.where(acctstoptime: nil, framedprotocol: '', account_id: tenant.id).where('acctupdatetime > ?', 2.minutes.ago).pluck(:framedipaddress).uniq.map(&:to_s)
      
    # offline_ips = RadAcct.where.not(acctstoptime: nil, framedprotocol: '').where.not('acctupdatetime > ?', 2.minutes.ago).where(account_id: tenant.id).pluck(:framedipaddress).uniq.map(&:to_s)
      trial_devices = FreeTrialDevice.where(
        account_id: tenant.id
      )
      

    Rails.logger.info "[Deletemacjob] Online IPs: #{online_ips.inspect}"
      RadCheck.where(
      username: mac,
      account_id: tenant.id
    ).destroy_all

    RadUserGroup.where(
      username: trial_devices.mac_address,
      account_id: tenant.id
    ).where(
      "groupname LIKE ?",
      "freetrial_%"
    ).destroy_all



    Rails.logger.info "[Deletemacjob] Marked OFFLINE: #{updated_offline}"
  end
end
