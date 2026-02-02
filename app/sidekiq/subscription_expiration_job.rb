


class SubscriptionExpirationJob
  include Sidekiq::Job
  queue_as :default
   sidekiq_options lock: :until_executed, lock_timeout: 0
  
  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
     
      subscriptions = Subscription.where(account_id: tenant.id)
      

subscriptions.each do |subscription|
  # next unless subscription.ppoe_username.present?

  # Fetch the PPPoE plan linked to this subscription/account
  plan = tenant&.pp_poe_plan

  expired_pppoe = plan&.expiry.present? && plan.expiry <= Time.current

  if expired_pppoe
    # Deny login by adding reject if not already there
    RadCheck.find_or_create_by!(
      username: subscription.ppoe_username,
      radiusattribute: 'Auth-Type',
      account_id: subscription.account_id,
      op: ':=',
      value: 'Reject'
    )
  else
    # Allow login by removing the reject entry if it exists
    RadCheck.where(
      username: subscription.ppoe_username,
      radiusattribute: 'Auth-Type',
      account_id: subscription.account_id,
      value: 'Reject'
    ).destroy_all
  end
end


        blocked_ppoe_subscriptions = Subscription.where(status:'blocked') 
        blocked_ppoe_subscriptions.find_each do |subscription|
          

             begin

 routers = NasRouter.where(account_id: subscription.account_id)
        routers.each do |router|


    router_ip = router.ip_address
    router_username = router.username
    router_password = router.password 
            # SSH into MikroTik router
             
              is_online = RadAcct.where(
      acctstoptime: nil,
      framedprotocol: 'PPP',
      framedipaddress: subscription.ip_address,
      
    ).where('acctupdatetime > ?', 3.minutes.ago).exists?


            Net::SSH.start(router_ip, router_username , password: router_password, verify_host_key: :never, non_interactive: true) do |ssh|

              if is_online
                  Rails.logger.info "Blocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik."
        Rails.logger.info("Blocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik.")
             ssh.exec!("ip firewall address-list add list=aitechs_blocked_list address=#{subscription.ip_address} comment=#{subscription.ppoe_username}")

              else
                Rails.logger.info "User #{subscription.ppoe_username} (#{subscription.ip_address}) is offline, not blocking."
                Rails.logger.info("User #{subscription.ppoe_username} (#{subscription.ip_address}) is offline, not blocking.")
              end

        
            
              # Update subscription status in DB
              subscription.update!(status: 'blocked')
            end
          rescue => e
            puts "Error blocking #{subscription.ppoe_username}: #{e.message}"
            Rails.logger.info("Error blocking #{subscription.ppoe_username}: #{e.message}")
          end

          
        end
        end







        expired_ppoe_subscriptions = Subscription.where("expiration_date <= ?", DateTime.current
        
        ).where(account_id: tenant.id)
        expired_ppoe_subscriptions.find_each do |subscription|

          begin
    # router = NasRouter.find_by(name: router_setting)
   

 routers = NasRouter.where(account_id: subscription.account_id)
        routers.each do |router|


    router_ip = router.ip_address
    router_username = router.username
    router_password = router.password
    
      is_online = RadAcct.where(
      acctstoptime: nil,
      framedprotocol: 'PPP',
      framedipaddress: subscription.ip_address,
      account_id: subscription.account_id
    ).where('acctupdatetime > ?', 3.minutes.ago).exists?
            # SSH into MikroTik router
            Net::SSH.start(router_ip, router_username , password: router_password, verify_host_key: :never, non_interactive: true) do |ssh|
              # Add the user's IP address to the MikroTik Address List
              if is_online
                ssh.exec!("ip firewall address-list add list=aitechs_blocked_list address=#{subscription.ip_address} comment=#{subscription.ppoe_username}")
                Rails.logger.info "Blocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik."

              else
                Rails.logger.info "User #{subscription.ppoe_username} (#{subscription.ip_address}) is offline, not blocking."
              end
        
              Rails.logger.info "Blocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik."
        Rails.logger.info("Blocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik.")
              # Update subscription status in DB
              subscription.update!(status: 'blocked')
              return if subscription.invoice_expired_created_at.present?

               package_price = Package.find_by(name: subscription.package_name).price
        SubscriberInvoice.find_or_create_by!(
                invoice_date: Time.current,
                invoice_number: generate_invoice_number,
                item: subscription.package_name,
                account_id: subscription.account_id,
                amount: package_price,
                status: "unpaid",
                description: "Subscription invoice for => #{subscription.package_name}",
                due_date: Time.current,
                subscriber_id: subscription.subscriber_id,
                subscription_id: subscription.id,
                
              )
              subscription.update_column(:invoice_expired_created_at, Time.current)
             

            end

          rescue => e
            puts "Error blocking #{subscription.ppoe_username}: #{e.message}"
            Rails.logger.info("Error blocking #{subscription.ppoe_username}: #{e.message}")
          end

          
        end
      end
        

    




      
    end



      end


    end

    private

    def generate_invoice_number
    "CUST#{rand(100..999)}"
  end



  end
 



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
# class SubscriptionExpirationJob
#   include Sidekiq::Job
#   queue_as :default


#   def perform
#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do
#         process_expired_subscriptions
#       end
#     end
#   end

#   private

#   def process_expired_subscriptions
#     Subscription.where("expiry <= ?", DateTime.current).find_each do |subscription|
#       block_subscription(subscription)
#     rescue => e
#       Rails.logger.error("Error blocking #{subscription.ppoe_username}: #{e.message}")
#     end
#   end

#   def block_subscription(subscription)
#     router = NasRouter.find_by(
#       account_id: ActsAsTenant.current_tenant.id,
#       name: ActsAsTenant.current_tenant.router_setting&.router_name
#     )
#     return unless router

#     Net::SSH.start(
#       router.ip_address,
#       router.username,
#       password: router.password,
#       timeout: 10 # Add timeout
#     ) do |ssh|
#       ssh.exec!("ip firewall address-list add list=aitechs_blocked_list address=#{subscription.ip_address} comment=#{subscription.ppoe_username}")
#       subscription.update!(status: 'blocked')
#       Rails.logger.info("Blocked #{subscription.ppoe_username} (#{subscription.ip_address})")
#     end
#   end
# end






