

class SubscriptionExpiredJob
  include Sidekiq::Job
  queue_as :default
  
  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
     
        


        expired_ppoe_subscriptions = Subscription.where("expiry <= ?", DateTime.current)

        expired_ppoe_subscriptions.find_each do |subscription|
          begin
            router_setting = ActsAsTenant.current_tenant&.router_setting&.router_name
    router = NasRouter.find_by(name: router_setting)

    return unless router

    router_ip = router.ip_address
    router_username = router.username
    router_password = router.password 
            # SSH into MikroTik router
            Net::SSH.start(router_ip, router_username , password: router_password) do |ssh|
              # Add the user's IP address to the MikroTik Address List
              ssh.exec!("ip firewall address-list add list=aitechs_blocked_list address=#{subscription.ip_address} comment=#{subscription.ppoe_username}")
        
              puts "Blocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik."
        
              # Update subscription status in DB
              subscription.update!(status: 'blocked')
            end
          rescue => e
            puts "Error blocking #{subscription.username}: #{e.message}"
          end
        end

        

      end
      end


    end


  end
