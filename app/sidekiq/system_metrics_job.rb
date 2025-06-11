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


log_output = `journalctl -u cloudflared -n 100 --no-pager --reverse`






    unless log_output.match?(%r{https://[a-z0-9-]+\.trycloudflare\.com})
      Rails.logger.warn "[Tunnel Monitor] No valid Cloudflare tunnel found. Restarting services..."

      # Restart cloudflared and your backend service
      `systemctl restart cloudflared`
      `systemctl restart aitechs-fiber8-backend`

      Rails.logger.info "[Tunnel Monitor] Services restarted successfully."
    else
      Rails.logger.info "[Tunnel Monitor] Tunnel is active. No action needed."
    end




    log_system_status = `systemctl status aitechs-fiber8-backend`
    # log_system_status.match?(%r{Blocked hosts})


    if log_system_status.match?(%r{Blocked hosts})
      `systemctl restart aitechs-fiber8-backend`
      # Rails.logger.info "System is blocked. No action needed."
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









