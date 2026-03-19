class AccessPointPingJob
  include Sidekiq::Job
  queue_as :default

  def perform
    Account.find_each do |tenant| # Iterate over all tenants
      ActsAsTenant.with_tenant(tenant) do

        nas_routers = AccessPoint.where(account_id: tenant.id)
        nas_routers.each do |nas_router|
          ip_address = nas_router.ip
          Rails.logger.info "Checking access point at #{ip_address} for tenant #{tenant.id}"

          begin
            reachable = false
            output = ""

            # TCP check instead of ping
            begin
              start_time = Time.now
              Socket.tcp(ip_address, 8728, connect_timeout: 2).close # use 8728 for MikroTik API, or choose appropriate port
              end_time = Time.now

              reachable = true
              output = "TCP connection successful (#{((end_time - start_time) * 1000).round(2)} ms)"
            rescue => e
              reachable = false
              output = "TCP connection failed: #{e.message}"
            end

            # Update model just like before
            nas_router.update!(
              reachable: reachable,
              response: output,
              checked_at: Time.current
            )

          rescue StandardError => e
            Rails.logger.error "AccessPointPingJob failed for tenant #{tenant.id}, IP #{ip_address}: #{e.message}"
          end
        end

      end
    end
  end
end