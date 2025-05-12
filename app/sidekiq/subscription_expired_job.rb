
# class SubscriptionExpiredJob
#   include Sidekiq::Job
#   queue_as :default
  
#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
     
        


#         expired_ppoe_subscriptions = Subscription.where("expiry <= ?", DateTime.current)

#         expired_ppoe_subscriptions.find_each do |subscription|
#           begin
#             router_setting = ActsAsTenant.current_tenant&.router_setting&.router_name
#     router = NasRouter.find_by(name: router_setting)

#     return unless router

#     router_ip = router.ip_address
#     router_username = router.username
#     router_password = router.password 
#             # SSH into MikroTik router
#             Net::SSH.start(router_ip, router_username , password: router_password) do |ssh|
#               # Add the user's IP address to the MikroTik Address List
#               ssh.exec!("ip firewall address-list add list=aitechs_blocked_list address=#{subscription.ip_address} comment=#{subscription.ppoe_username}")
        
#               puts "Blocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik."
#         Rails.logger.info("Blocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik.")
#               # Update subscription status in DB
#               subscription.update!(status: 'blocked')
#             end
#           rescue => e
#             puts "Error blocking #{subscription.username}: #{e.message}"
#             Rails.logger.error("Error blocking #{subscription.username}: #{e.message}")
#           end
#         end

        

#       end
#       end


#     end


#   end
# app/jobs/subscription_expired_job.rb
 



# class SubscriptionExpiredJob
#   include Sidekiq::Worker

#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
#         expired_ppoe_subscriptions = Subscription.where("expiry <= ?", DateTime.current)

#         expired_ppoe_subscriptions.find_each do |subscription|
#           begin
#             router_setting = ActsAsTenant.current_tenant&.router_setting&.router_name
#             router = NasRouter.find_by(name: router_setting)
#             next unless router

#             Net::SSH.start(
#               router.ip_address,
#               router.username,
#               password: router.password
#             ) do |ssh|
#               ssh.exec!("ip firewall address-list add list=aitechs_blocked_list address=#{subscription.ip_address} comment=#{subscription.ppoe_username}")
#               Rails.logger.info("Blocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik.")
#               subscription.update!(status: 'blocked')
#             end
#           rescue => e
#             Rails.logger.error("Error blocking #{subscription.ppoe_username}: #{e.message}")
#           end
#         end
#       end
#     end
#   end
# end





# app/jobs/subscription_expired_job.rb
class SubscriptionExpiredJob
  include Sidekiq::Worker
  sidekiq_options queue: 'default'

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        process_expired_subscriptions
      end
    end
  end

  private

  def process_expired_subscriptions
    Subscription.where("expiry <= ?", DateTime.current).find_each do |subscription|
      block_subscription(subscription)
    rescue => e
      Rails.logger.error("Error blocking #{subscription.ppoe_username}: #{e.message}")
    end
  end

  def block_subscription(subscription)
    router = NasRouter.find_by(
      account_id: ActsAsTenant.current_tenant.id,
      name: ActsAsTenant.current_tenant.router_setting&.router_name
    )
    return unless router

    Net::SSH.start(
      router.ip_address,
      router.username,
      password: router.password,
      timeout: 10 # Add timeout
    ) do |ssh|
      ssh.exec!("ip firewall address-list add list=aitechs_blocked_list address=#{subscription.ip_address} comment=#{subscription.ppoe_username}")
      subscription.update!(status: 'blocked')
      Rails.logger.info("Blocked #{subscription.ppoe_username} (#{subscription.ip_address})")
    end
  end
end






