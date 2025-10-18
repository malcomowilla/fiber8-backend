
class LoadRadiusJob 

  include Sidekiq::Job
  queue_as :default




  def perfom
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do


          Na.unscoped.where(
       
          shortname: nil, 
          secret: nil,
    
        account_id: nil
        ).find_each do |radius|
          begin
            radius.update!(account_id: tenant.id,
            secret: '$rends6$#b8',
             shortname: 'superadmin',
            )
          rescue => e
            # Rails.logger.error "Failed to update radacct with id #{radacct.id}: #{e.message}"
          end
        end
        




      end
    end


  end




end



