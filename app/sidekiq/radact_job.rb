

class RadactJob
  include Sidekiq::Job
  queue_as :default
  
  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
    # Ensure ActsAsTenant is set for the current tenant, else set it manually if needed
    # ActsAsTenant.current_tenant = Tenant.find(1)  # Or dynamically find the current tenant
    nil_radacct_count = RadAcct.where(account_id: nil).count
    Rails.logger.info "Found #{nil_radacct_count} RadAcct records with nil account_id for tenant #{ActsAsTenant.current_tenant.id}"
    
    # Update all RadAcct records where account_id is nil
    RadAcct.where(account_id: nil).find_each do |radacct|
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


  



  end
      end






      end



end