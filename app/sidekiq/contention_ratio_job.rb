class ContentionRatioJob
  include Sidekiq::Job

  def perform
    routers = NasRouter.all

    routers.each do |router|
      begin
        router_ip = router.ip_address
        router_username = router.username
        router_password = router.password

        Net::SSH.start(router_ip, router_username, password: router_password, verify_host_key: :never) do |ssh|

          # Fetch active PPPoE users
          active_users_raw = ssh.exec!('/ppp active print detail without-paging')
          active_users = parse_active_pppoe_users(active_users_raw)

          active_users.each do |user|
            subscription = Subscription.find_by(ppoe_username: user[:username])
            next unless subscription

            package = Package.find_by(name: subscription.package_name, router_name: router.name)
            next unless package && package.aggregation.present?

            aggregation_ratio = package.aggregation.to_i
            download_limit = package.download_limit.to_f
            upload_limit = package.upload_limit.to_f

            # Calculate shared speed
            shared_download = (download_limit / aggregation_ratio).round(2)
            shared_upload = (upload_limit / aggregation_ratio).round(2)

            # Add simple queue for the user
            queue_name = "queue_#{user[:username]}"
            target_ip = subscription.ip_address

            next if target_ip.blank?

            # Add queue (no check for existing queue)
            limit_cmd  = "queue simple add name=#{queue_name} target=#{target_ip} max-limit=#{shared_upload}M/#{shared_download}M burst-threshold=#{package.burst_threshold_upload}/#{package.burst_threshold_download} burst-time=#{package.burst_time} burst-limit=#{package.burst_upload_speed}/#{package.burst_download_speed}"
            
         Rails.logger.info "[ContentionRatioJob] Adding queue for user #{user[:username]} on router #{router.name}: #{limit_cmd}"

            ssh.exec!(limit_cmd)
          end
        end
      rescue => e
        Rails.logger.error "[ContentionRatioJob] Error for router #{router.name}: #{e.message}"
      end
    end
  end

  private

  # Parses usernames from MikroTik output
  def parse_active_pppoe_users(raw_output)
    raw_output.lines.map do |line|
      if line.include?("user=")
        match = line.match(/name="(?<username>[^"]+)"/)
        { username: match[:username] } if match
      end
    end.compact
  end
end
