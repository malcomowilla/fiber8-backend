


class PopulateRadiusJob
include Sidekiq::Job
 queue_as :default




 def perform

   Rails.logger.info "Populating Radius"
   Account.find_each do |account|

      routers = NasRouter.where(account_id: account.id)

      next if routers.blank?
     ActsAsTenant.with_tenant(account) do
       Rails.logger.info "Populating Radius for #{account.subdomain}"

       routers.find_each do |nas_router|
           nas = Na.find_or_initialize_by(nasname: nas_router.ip_address)




nas.update!(
shortname: 'admin', secret: nas_router.password,
account_id: account.id
)

       end
         
     end
       end
 end






end