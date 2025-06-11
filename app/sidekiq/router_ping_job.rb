require 'open3'

class RouterPingJob
  include Sidekiq::Job
  queue_as :default

  def perform


    
    Account.find_each do |tenant| # Iterate over all tenants
      ActsAsTenant.with_tenant(tenant) do




# ActsAsTenant.current_tenant = Tenant.find(1)  # Or dynamically find the current tenant
nil_radacct_count = RadAcct.unscoped.where(account_id: nil).count
Rails.logger.info "Found #{nil_radacct_count} RadAcct records with nil account_id for tenant #{ActsAsTenant.current_tenant.id}"

# Update all RadAcct records where account_id is nil
#         RadAcct.unscoped.where(account_id: nil).find_each do |radacct|
RadAcct.unscoped.where(account_id: nil).find_each do |radacct|

  # Rails.logger.info "radct update in job#{radacct}"
  # radacct.update!(account_id: ActsAsTenant.current_tenant.id)
  # RadAcct.where(account_id: nil).find_each do |radacct|
if radacct
begin
  radacct.update!(account_id: ActsAsTenant.current_tenant.id)
rescue => e
  Rails.logger.error "Failed to update radacct with id #{radacct.id}: #{e.message}"
end
else
Rails.logger.info "No radacct found with nil account_id."
end
end





        unless tenant.router_setting&.router_name
          Rails.logger.info "No router setting found for tenant #{tenant.id}"
          next
        end

        nas_router = NasRouter.find_by(name: tenant.router_setting.router_name)
        unless nas_router
          Rails.logger.error "NAS router not found for name: #{tenant.router_setting.router_name}"
          next
        end

        ip_address = nas_router.ip_address
        Rails.logger.info "Pinging router at #{ip_address} for tenant #{tenant.id}"

        begin
          output = `ping -c 3 #{ip_address}`
          reachable = $?.success?

          if reachable
            Rails.logger.info "Ping successful: #{output}"
          else
            Rails.logger.warn "Ping failed: #{output}"
          end

          cache_data = RouterStatus.first_or_initialize(
            tenant_id: tenant.id,
            ip: ip_address,
            reachable: reachable,
            response: output,
            checked_at: Time.current
          )
          cache_data.update(
            tenant_id: tenant.id,
            ip: ip_address,
            reachable: reachable,
            response: output,
            checked_at: Time.current

          )
          Rails.logger.info "Cache key 'router_status_#{tenant.id}' written with data: #{cache_data.inspect}"
        rescue StandardError => e
          Rails.logger.error "RouterPingJob failed for tenant #{tenant.id}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end
    end
  end
end