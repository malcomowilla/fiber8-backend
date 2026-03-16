

class AccessPointPingJob
    include Sidekiq::Job
   queue_as :default



      def perform

        Account.find_each do |tenant| # Iterate over all tenants
      ActsAsTenant.with_tenant(tenant) do

  nas_routers = AccessPoint.where(account_id: tenant.id)
        nas_routers.each do |nas_router|
          ip_address = nas_router.ip
          Rails.logger.info "Pinging access point at #{ip_address} for tenant #{tenant.id}"

          begin
            output, status = Open3.capture2e("ping -c 3 #{ip_address}")
            reachable = status.success?

            if reachable
               nas_router.update!(
                reachable: reachable,
                response: output,
                checked_at: Time.current
              )
            else
               nas_router.update!(
                reachable: reachable,
                response: output,
                checked_at: Time.current
              )
            end

          end




      end
      end
      end
      





end
end