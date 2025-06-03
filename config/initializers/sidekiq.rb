# # config/initializers/sidekiq.rb
# Sidekiq.configure_server do |config|
#   config.redis = { url: 'redis://localhost:6379/0' }
#     config.on(:startup) do
#       Sidekiq.schedule = {
        
#         'router_ping_job' => {
#         'class' => 'RouterPingJob',
#         'cron' => '* * * * *' # Run every minute
#       }
#       }
#       Sidekiq::Scheduler.reload_schedule!
#     end
#   end
  



require 'sidekiq'
require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0' }

  config.on(:startup) do
    schedule = {



  # 'hotspot_expiration_job' => {
  #   'class' => 'HotspotExpirationJob',
  #   'cron' => '* * * * *'
  # },



  # 'router_ping_job' => {
  #   'class' => 'RouterPingJob',
  #   'cron' => '* * * * *' # Run every 4 minutes
  # },
      


  # 'subscription_expiration_job' => {
  #         'class' => 'SubscriptionExpirationJob',
  #         'cron' => '* * * * *', # Every minute
  #       },



# 'system_metrics_job' => {
#   'class' => 'SystemMetricsJob',
#   'cron' => '* * * * *' # Run every minute
# },


'inactivity_check_job' => {
  'class' => 'InactivityCheckJob',
  'cron' => '* * * * *' # Run every minute
},

  


   


     
      
    }

    Sidekiq.schedule = schedule
    Sidekiq::Scheduler.reload_schedule!
    Rails.logger.info("Sidekiq schedule loaded: #{Sidekiq.schedule.inspect}")

  end
end
