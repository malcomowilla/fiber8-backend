  class RemoveBlockedListExtendedJob < ApplicationJob
    queue_as :default
    require 'net/ssh'
    require 'ipaddr'
    require 'open3'


    def perform(subscription)
      begin
        
     nas = IpNetwork.find_by(title: subscription.network_name).nas

     
        router = NasRouter.find_by(name: nas)
      
        return unless router
        
        router_ip = router.ip_address
        router_username = router.username
        router_password = router.password 
        
        # Connect via SSH to MikroTik
        Net::SSH.start(router_ip, router_username, password: router_password, verify_host_key: :never, non_interactive: true) do |ssh|
          # Correct command to remove active PPPoE session based on pppoe_username
          command = "/ip firewall address-list remove [find list=aitechs_blocked_list address=#{subscription.ip_address}]"
          
          # Execute the command
          ssh.exec!(command)
          subscription.update!(status: 'active')
          puts "UnBlocked #{subscription.ppoe_username} (#{subscription.ip_address}) on MikroTik."
        end
      rescue StandardError => e
        Rails.logger.error "Error removing PPPoE connection for username #{subscription.ppoe_username}: #{e.message}"
      end
  
  end
end




