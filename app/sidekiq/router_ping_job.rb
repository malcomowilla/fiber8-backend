

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

#     # Update RouterStatus just like before
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



























# #  nas_routers.each do |nas_router|
# #           ip_address = nas_router.ip_address
# #           Rails.logger.info "Pinging router at #{ip_address} for tenant #{tenant.id}"

# #           begin
# #             output, status = Open3.capture2e("ping -c 3 #{ip_address}")
# #             reachable = status.success?

# #             if reachable
# #               # Rails.logger.info "Ping successful: #{output}"
# #             else
# #               # Rails.logger.warn "Ping failed: #{output}"
# #             end

       
# #         RouterStatus.find_or_initialize_by(
# #               tenant_id: tenant.id,
# #               ip: ip_address
# #             ).update(
# #               reachable: reachable,
# #               response: output,
# #               checked_at: Time.current
# #             )
# #             # Rails.logger.info "Router status updated for tenant #{tenant.id}"
# #           rescue StandardError => e
# #             # Rails.logger.error "RouterPingJob failed for tenant #{tenant.id}: #{e.message}"
# #             # Rails.logger.error e.backtrace.join("\n")
# #           end
# #         end
# 
#
#
class RouterPingJob
  include Sidekiq::Job
  queue_as :default

  MIKROTIK_API_PORT = 8728

  def perform
    # -----------------------------------------
    # PASS 1 — RadAcct account_id backfill (unchanged, per-tenant work)
    # -----------------------------------------
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        subscriptions = Subscription.where.not(ip_address: [nil, ''])
        subscriptions.each do |subscription|
          RadAcct.unscoped.where(
            framedipaddress: subscription.ip_address,
            username: subscription.ppoe_username,
            account_id: nil
          ).find_each do |radacct|
            begin
              radacct.update!(account_id: tenant.id)
            rescue => e
              Rails.logger.error "Failed to update radacct #{radacct.id}: #{e.message}"
            end
          end
        end

        hotspot_subscriptions = HotspotVoucher.where.not(voucher: [nil, ''])
        hotspot_subscriptions.find_each do |subscription|
          RadAcct.unscoped.where(
            username: subscription.voucher,
            account_id: nil
          ).find_each do |radacct|
            begin
              radacct.update!(account_id: tenant.id)
            rescue => e
              Rails.logger.error "Failed to update radacct #{radacct.id}: #{e.message}"
            end
          end
        end
      end
    end

    # -----------------------------------------
    # PASS 2 — Gather all router IPs across all tenants
    # -----------------------------------------
    router_targets = [] # [{ tenant_id:, router_id:, ip: }]

    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        NasRouter.where(account_id: tenant.id).find_each do |nas_router|
          next if nas_router.ip_address.blank?

          router_targets << {
            tenant_id: tenant.id,
            router_id: nas_router.id,
            ip: nas_router.ip_address
          }
        end
      end
    end

    return if router_targets.empty?

    # -----------------------------------------
    # PASS 3 — One SSH round-trip checks every router IP via the AWS box
    # -----------------------------------------
    ip_port_pairs = router_targets.map { |t| [t[:ip], MIKROTIK_API_PORT] }.uniq
    results = RemoteWireguardExecutor.batch_tcp_check(ip_port_pairs)

    # -----------------------------------------
    # PASS 4 — Write RouterStatus per tenant using the batched results
    # -----------------------------------------
    router_targets.each do |target|
      result = results[target[:ip]] || { reachable: false, message: "No result returned" }

      ActsAsTenant.with_tenant(Account.find(target[:tenant_id])) do
        RouterStatus.find_or_initialize_by(
          tenant_id: target[:tenant_id],
          ip: target[:ip]
        ).update(
          reachable: result[:reachable],
          response: result[:message],
          checked_at: Time.current
        )
      end
    end
  end
end