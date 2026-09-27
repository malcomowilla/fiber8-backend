
# require 'open3'

# class RouterPingJob
#   include Sidekiq::Job
#   queue_as :default

#   def perform





    
#     Account.find_each do |tenant| 
#       ActsAsTenant.with_tenant(tenant) do

        


        




#               subscriptions = Subscription.where.not(ip_address: [nil, ''])
#               subscriptions.each do |subscription|
#         # Process RadAcct records with nil account_id
#         nil_radacct_count = RadAcct.unscoped.where(
        
#           framedipaddress: subscription.ip_address,
#           username: subscription.ppoe_username,
#           account_id: nil
#         ).count
#         Rails.logger.info "Found #{nil_radacct_count} RadAcct records with nil account_id for tenant #{tenant.id}"

#         RadAcct.unscoped.where(
#         framedipaddress: subscription.ip_address,
#         username: subscription.ppoe_username,
#         account_id: nil
#         ).find_each do |radacct|
#           begin
#             radacct.update!(account_id: tenant.id)
#           rescue => e
#             # Rails.logger.error "Failed to update radacct with id #{radacct.id}: #{e.message}"
#           end
#         end
#         end






#    hotspot_subscriptions = HotspotVoucher.where.not(voucher: [nil, ''])
#                hotspot_subscriptions.find_each do |subscription|
#         # Process RadAcct records with nil account_id
#         nil_radacct_count = RadAcct.unscoped.where(
        
#           username: subscription.voucher,
#           account_id: nil
#         ).count
#         Rails.logger.info "Found #{nil_radacct_count} RadAcct records with nil account_id for tenant hotspot voucher #{tenant.id}"

#         RadAcct.unscoped.where(
#            username: subscription.voucher,
#         account_id: nil
#         ).find_each do |radacct|
#           begin
#             radacct.update!(account_id: tenant.id)
#           rescue => e
#             # Rails.logger.error "Failed to update radacct with id #{radacct.id}: #{e.message}"
#           end
#         end
#         end








#         # Check router status
#         nas_routers = NasRouter.where(account_id: tenant.id)
#         nas_routers.find_each do |nas_router|
#   ip_address = nas_router.ip_address
#   Rails.logger.info "Checking router at #{ip_address} for tenant #{tenant.id}"

#   begin
#     # Use Socket.tcp instead of ping
#     reachable = false
#     output = ""

#     begin
#       start_time = Time.now
#       Socket.tcp(ip_address, 8728, connect_timeout: 2).close
#       end_time = Time.now

#       reachable = true
#       output = "TCP connection successful (#{((end_time - start_time) * 1000).round(2)} ms)"
#     rescue => e
#       reachable = false
#       output = "TCP connection failed: #{e.message}"
#     end

#     RouterStatus.find_or_initialize_by(
#       tenant_id: tenant.id,
#       ip: ip_address
#     ).update(
#       reachable: reachable,
#       response: output,
#       checked_at: Time.current
#     )

#   rescue StandardError => e
#     Rails.logger.error "Router check failed for tenant #{tenant.id}, router #{ip_address}: #{e.message}"
#   end
# end
       
#       end
#     end
#   end
# end


require 'open3'

class RouterPingJob
  include Sidekiq::Job
  queue_as :default

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        subscriptions = Subscription.where.not(ip_address: [nil, ''])
        subscriptions.each do |subscription|
          nil_radacct_count = RadAcct.unscoped.where(
            framedipaddress: subscription.ip_address,
            username: subscription.ppoe_username,
            account_id: nil
          ).count
          Rails.logger.info "Found #{nil_radacct_count} RadAcct records with nil account_id for tenant #{tenant.id}"

          RadAcct.unscoped.where(
            framedipaddress: subscription.ip_address,
            username: subscription.ppoe_username,
            account_id: nil
          ).find_each do |radacct|
            begin
              radacct.update!(account_id: tenant.id)
            rescue => e
              # Rails.logger.error "Failed to update radacct with id #{radacct.id}: #{e.message}"
            end
          end
        end

        hotspot_subscriptions = HotspotVoucher.where.not(voucher: [nil, ''])
        hotspot_subscriptions.find_each do |subscription|
          nil_radacct_count = RadAcct.unscoped.where(
            username: subscription.voucher,
            account_id: nil
          ).count
          Rails.logger.info "Found #{nil_radacct_count} RadAcct records with nil account_id for tenant hotspot voucher #{tenant.id}"

          RadAcct.unscoped.where(
            username: subscription.voucher,
            account_id: nil
          ).find_each do |radacct|
            begin
              radacct.update!(account_id: tenant.id)
            rescue => e
              # Rails.logger.error "Failed to update radacct with id #{radacct.id}: #{e.message}"
            end
          end
        end

        # Check router status
        nas_routers = NasRouter.where(account_id: tenant.id)
        nas_routers.find_each do |nas_router|
          ip_address = nas_router.ip_address
          Rails.logger.info "Checking router at #{ip_address} for tenant #{tenant.id}"

          begin
            reachable = false
            output = ""

            begin
              start_time = Time.now
              Socket.tcp(ip_address, 8728, connect_timeout: 2).close
              end_time = Time.now

              reachable = true
              output = "TCP connection successful (#{((end_time - start_time) * 1000).round(2)} ms)"
            rescue => e
              reachable = false
              output = "TCP connection failed: #{e.message}"
            end

            # Only write a log row when reachability actually flips — keeps
            # the log table a history of outages/recoveries, not a dump of
            # every 35s poll. Compared against the *log's own* last entry,
            # not RouterStatus: RouterStatus predates this feature and may
            # already read `false` for a router that was down before this
            # shipped, which would silently swallow that outage forever.
            last_log = RouterStatusLog.where(nas_router_id: nas_router.id, tenant_id: tenant.id)
                                       .order(occurred_at: :desc).first
            status_changed = last_log.nil? || last_log.reachable != reachable

            RouterStatus.find_or_initialize_by(
              tenant_id: tenant.id,
              ip: ip_address
            ).update(
              reachable: reachable,
              response: output,
              checked_at: Time.current
            )

            if status_changed
              RouterStatusLog.create(
                nas_router_id: nas_router.id,
                tenant_id: tenant.id,
                ip: ip_address,
                reachable: reachable,
                response: output,
                occurred_at: Time.current
              )
            end

          rescue StandardError => e
            Rails.logger.error "Router check failed for tenant #{tenant.id}, router #{ip_address}: #{e.message}"
          end
        end
      end
    end
  end
end