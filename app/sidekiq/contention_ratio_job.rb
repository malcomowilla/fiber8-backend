



class ContentionRatioJob
  include Sidekiq::Job

  def perform(*args)
    

    begin
        

     
        routers = NasRouter.all
      
        return unless router
        
        router_ip = router.ip_address
        router_username = router.username
        router_password = router.password 
        
        # Connect via SSH to MikroTik
        Net::SSH.start(router_ip, router_username, password: router_password, verify_host_key: :never, non_interactive: true) do |ssh|
          # Correct command to remove active PPPoE session based on pppoe_username
          command = "/ppp active"
          
          # Execute the command
          ssh.exec!(command)
        end
      rescue StandardError => e
        Rails.logger.error "Error removing PPPoE connection for username #{ppoe_username}: #{e.message}"
      end
  


  
  end
end

