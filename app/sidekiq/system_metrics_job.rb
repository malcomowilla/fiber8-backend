# require 'sys/proctable'
# require 'sys/filesystem'

# class SystemMetricsJob
#   include Sidekiq::Job
#   queue_as :default

#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
#         load_avg = File.read('/proc/loadavg').split[0..2].join(', ')
#         mem_info = File.readlines('/proc/meminfo').map { |line| line.split(':').map(&:strip) }.to_h
#         disk_info = Sys::Filesystem.stat('/')
#         current_time = Time.now.strftime("%B %d, %Y %H:%M:%S UTC") # Format timestamp

#         # CPU Usage Calculation
#         cpu_stats_before = File.readlines('/proc/stat').grep(/^cpu /).first.split.map(&:to_f)
#         sleep 1
#         cpu_stats_after = File.readlines('/proc/stat').grep(/^cpu /).first.split.map(&:to_f)

#         idle_before, total_before = cpu_stats_before[4], cpu_stats_before.sum
#         idle_after, total_after = cpu_stats_after[4], cpu_stats_after.sum

#         cpu_usage = 100.0 * (1 - (idle_after - idle_before) / (total_after - total_before))

#         # Convert values to human-readable format
#         metrics = {
#           time: current_time,
#           cpu_usage: "#{cpu_usage.round(2)}%",  # Add percentage
#           # memory_total: "#{(mem_info['MemTotal'].to_i / 1024).round(2)} MB",  # Convert to MB
#           # memory_free: "#{(mem_info['MemFree'].to_i / 1024).round(2)} MB",
#           memory_total: "#{(mem_info['MemTotal'].to_i / 1_048_576.0).round(2)} GB",  # Convert to GB
#     memory_free: "#{(mem_info['MemFree'].to_i / 1_048_576.0).round(2)} GB",  # Convert to GB

#           disk_total: "#{(disk_info.bytes_total.to_f / (1024 * 1024 * 1024)).round(2)} GB",
#           disk_free: "#{(disk_info.bytes_free.to_f / (1024 * 1024 * 1024)).round(2)} GB",
#           load_average: load_avg
#         }

#         # Log metrics for debugging
#         Rails.logger.info "System Metrics: #{metrics}"

#         # Save to database in a structured format
#         sys = SystemMetric.first_or_initialize(
#           cpu_usage: metrics[:cpu_usage],
#           memory_total: metrics[:memory_total],
#           memory_free: metrics[:memory_free],
#           disk_total: metrics[:disk_total],
#           disk_free: metrics[:disk_free],
#           load_average: metrics[:load_average],
#           account_id: ActsAsTenant.current_tenant.id
#         )
#         sys.update(
#           cpu_usage: metrics[:cpu_usage],
#           memory_total: metrics[:memory_total],
#           memory_free: metrics[:memory_free],
#           disk_total: metrics[:disk_total],
#           disk_free: metrics[:disk_free],
#           load_average: metrics[:load_average],
#           account_id: ActsAsTenant.current_tenant.id
#         ) 

#          Rails.logger.info "System Metrics2 saved: #{sys.inspect}"
#       end
#     end
#   end
# end


require 'sys/proctable'
require 'sys/filesystem'

class SystemMetricsJob
  include Sidekiq::Job
  queue_as :default

  def perform



NasRouter.all.each do |router|
      begin
        router_ip       = router.ip_address
        router_username = router.username
        router_password = router.password

        # Step 1: Fetch active PPPoE users
        active_users = fetch_active_users(router_ip, router_username, router_password)
        next if active_users.blank?

        active_users.each do |user|
          pppoe_username = user['name']
          subscription   = Subscription.find_by(ppoe_username: pppoe_username)
          next unless subscription

          package = Package.find_by(name: subscription.package_name, router_name: router.name)
          next unless package&.aggregation.present?

          aggregation_ratio = package.aggregation.to_i
          download_limit    = package.download_limit.to_f
          upload_limit      = package.upload_limit.to_f

          shared_download = (download_limit / aggregation_ratio).round(2)
          shared_upload   = (upload_limit / aggregation_ratio).round(2)

          queue_name = "queue_#{pppoe_username}"
          target_ip  = subscription.ip_address
          next if target_ip.blank?

          # Step 2: Check if queue already exists
          if queue_exists?(router_ip, router_username, router_password, queue_name)
            Rails.logger.info "[ContentionRatioJob] Queue exists for #{queue_name}, skipping."
            next
          end

          # Step 3: Add queue
          payload = {
            name: queue_name,
            target: target_ip,
            "max-limit": "#{shared_upload}M/#{shared_download}M",
            "burst-threshold": "#{package.burst_threshold_upload}/#{package.burst_threshold_download}",
            "burst-limit": "#{package.burst_upload_speed}/#{package.burst_download_speed}",
            "burst-time": package.burst_time.to_s
          }

          add_queue(router_ip, router_username, router_password, payload)
          Rails.logger.info "[ContentionRatioJob] Queue added for #{queue_name}"
        end
      rescue => e
        Rails.logger.info "[ContentionRatioJob] Error for router #{router.name}: #{e.message}"
      end
    end



    def fetch_active_users(ip, username, password)
    uri = URI("http://#{ip}/rest/ppp/active")
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(username, password)

    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    return [] unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  rescue => e
    Rails.logger.info "Failed to fetch active users: #{e.message}"
    []
  end

  def queue_exists?(ip, username, password, queue_name)
    uri = URI("http://#{ip}/rest/queue/simple/find?name=#{queue_name}")
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(username, password)

    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

    res.is_a?(Net::HTTPSuccess) && JSON.parse(res.body).any?
  rescue => e
    Rails.logger.info "Failed to check queue #{queue_name} existence: #{e.message}"
    false
  end

  def add_queue(ip, username, password, payload)
    uri = URI("http://#{ip}/rest/queue/simple/add")
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.basic_auth(username, password)
    req.body = payload.to_json

    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

    unless res.is_a?(Net::HTTPSuccess)
      raise "Failed to add queue: #{res.body}"
    end
  end








log_output = `journalctl -u loophole -n 200 --no-page`


    unless log_output.match(%r{https://([a-z0-9\-]+\.loophole\.site)})
      Rails.logger.warn "[Tunnel Monitor] No valid Cloudflare tunnel found. Restarting services..."

      # Restart cloudflared and your backend service
      `systemctl restart loophole`
      `systemctl restart aitechs-fiber8-backend`

      Rails.logger.info "[Tunnel Monitor] Services restarted successfully."
    else
      Rails.logger.info "[Tunnel Monitor] Tunnel is active. No action needed."
    end





    

    # log_system_status = `systemctl status aitechs-fiber8-backend`
    # log_system_status.match?(%r{Blocked hosts})


    # if log_system_status.match?(%r{Blocked hosts})
    #   `systemctl restart aitechs-fiber8-backend`
    #   Rails.logger.info "System is blocked. No action needed."
    # end

Rails.logger.info "Rehydrating wireguard"
    WireguardPeer.find_each do |peer|
      # `wg set wg0 peer #{peer.public_key} allowed-ips #{peer.allowed_ips}, 192.168.50.47/32`
        if peer.private_ip.nil?
              `wg set wg0 peer #{peer.public_key} allowed-ips #{peer.allowed_ips}`
            else
              `ip route add #{peer.private_ip} dev wg0`

               `wg set wg0 peer #{peer.public_key} allowed-ips #{peer.allowed_ips},#{peer.private_ip}`

            end

    end

    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do





        unless RUBY_PLATFORM =~ /linux/
          Rails.logger.info "SystemMetricsJob skipped: Not running on a linux system."
          
          sys = SystemMetric.first_or_initialize(
            cpu_usage: '0%',
            memory_total: '0GB',
            memory_free: '0GB',
            memory_used: '0GB', # Save memory used
            disk_total: '0GB',
            disk_free: '0GB',
            disk_used: '0GB', # Save disk used
            load_average: 0,
            uptime: 0,
            account_id: ActsAsTenant.current_tenant&.id
          )
          sys.update(
            cpu_usage: '0%',
            memory_total: '0GB',
            memory_free: '0GB',
            memory_used: '0GB', # Save memory used
            disk_total: '0GB',
            disk_free: '0GB',
            disk_used: '0GB', # Save disk used
            load_average: 0,
            uptime: 0,
            account_id: ActsAsTenant.current_tenant.id
          ) 
          return
        end



        load_avg = File.read('/proc/loadavg').split[0..2].join(', ')
        mem_info = File.readlines('/proc/meminfo').map { |line| line.split(':').map(&:strip) }.to_h
        disk_info = Sys::Filesystem.stat('/')
        current_time = Time.now.strftime("%B %d, %Y %H:%M:%S UTC") # Format timestamp

        # CPU Usage Calculation
        cpu_stats_before = File.readlines('/proc/stat').grep(/^cpu /).first.split.map(&:to_f)
        sleep 1
        cpu_stats_after = File.readlines('/proc/stat').grep(/^cpu /).first.split.map(&:to_f)

        idle_before, total_before = cpu_stats_before[4], cpu_stats_before.sum
        idle_after, total_after = cpu_stats_after[4], cpu_stats_after.sum

        cpu_usage = 100.0 * (1 - (idle_after - idle_before) / (total_after - total_before))

        # Convert values to human-readable format
        memory_total_gb = (mem_info['MemTotal'].to_i / 1_048_576.0).round(2) # Convert to GB
        memory_free_gb = (mem_info['MemFree'].to_i / 1_048_576.0).round(2)  # Convert to GB
        memory_used_gb = (memory_total_gb - memory_free_gb).round(2) # Used memory

        disk_total_gb = (disk_info.bytes_total.to_f / (1024 * 1024 * 1024)).round(2)
        disk_free_gb = (disk_info.bytes_free.to_f / (1024 * 1024 * 1024)).round(2)
        disk_used_gb = (disk_total_gb - disk_free_gb).round(2) # Used disk space


        # uptime_seconds = File.read('/proc/uptime').split.first.to_i
        # uptime = Time.at(uptime_seconds).utc.strftime("%H:%M:%S") # Convert to HH:MM:SS format
        
        uptime = `uptime -p`.strip
        metrics = {
          time: current_time,
          cpu_usage: "#{cpu_usage.round(2)}%",
          memory_total: "#{memory_total_gb} GB",
          memory_free: "#{memory_free_gb} GB",
          memory_used: "#{memory_used_gb} GB", # Added memory used
          disk_total: "#{disk_total_gb} GB",
          disk_free: "#{disk_free_gb} GB",
          disk_used: "#{disk_used_gb} GB", # Added disk used
          load_average: load_avg,
          uptime: uptime
        }

       

        # Log metrics for debugging
        Rails.logger.info "System Metrics: #{metrics}"

        # Save to database
        sys = SystemMetric.first_or_initialize(
          cpu_usage: metrics[:cpu_usage],
          memory_total: metrics[:memory_total],
          memory_free: metrics[:memory_free],
          memory_used: metrics[:memory_used], # Save memory used
          disk_total: metrics[:disk_total],
          disk_free: metrics[:disk_free],
          disk_used: metrics[:disk_used], # Save disk used
          load_average: metrics[:load_average],
          uptime: metrics[:uptime],
          account_id: ActsAsTenant.current_tenant.id
        )
        sys.update(
          cpu_usage: metrics[:cpu_usage],
          memory_total: metrics[:memory_total],
          memory_free: metrics[:memory_free],
          memory_used: metrics[:memory_used], # Save memory used
          disk_total: metrics[:disk_total],
          disk_free: metrics[:disk_free],
          disk_used: metrics[:disk_used], # Save disk used
          load_average: metrics[:load_average],
          uptime: metrics[:uptime],
          account_id: ActsAsTenant.current_tenant.id
        ) 

        Rails.logger.info "System Metrics saved: #{sys.inspect}"
      end
    end
  end
end









