class HotspotExpirationJob
  include Sidekiq::Job
  queue_as :default

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        expired_vouchers = HotspotVoucher.where("expiration <= ?", Time.current)

        expired_vouchers.each do |voucher|
          logout_hotspot_user(voucher)
          voucher.update!(status: 'expired')  # Mark as expired in DB
        end
      end
    end
  end

  private

  def logout_hotspot_user(voucher)

    router_setting = ActsAsTenant.current_tenant&.router_setting&.router_name
    

    ip_address = NasRouter.find_by(name:router_setting)&.ip_address
    username = NasRouter.find_by(name:router_setting)&.username
    password = NasRouter.find_by(name:router_setting)&.password


    router_ip =  ip_address # Replace with your MikroTik router IP
    router_username = username
    router_password = password 

    remove_command = "/ip hotspot active remove [find user=#{voucher.voucher}]"

    begin
      Net::SSH.start(router_ip, router_username, password: router_password, verify_host_key: :never) do |ssh|
        output = ssh.exec!(remove_command)
        Rails.logger.info("Successfully removed user #{voucher.voucher}: #{output}")
      end
    rescue Net::SSH::AuthenticationFailed
      Rails.logger.error("SSH authentication failed for MikroTik router")
    rescue StandardError => e
      Rails.logger.error("Failed to logout user #{voucher.voucher}: #{e.message}")
    end
  end
end
