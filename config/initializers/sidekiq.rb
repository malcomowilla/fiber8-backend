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
      # 'router_ping_job' => {
      #   'class' => 'RouterPingJob',
      #   'cron' => '* * * * *' # Run every minute
      # },
      'router_ping_job' => {
  'class' => 'RouterPingJob',
  'cron' => '*/4 * * * *' # Run every 4 minutes
},


'subscription_expired_job' => {
  'class' => 'SubscriptionExpiredJob',
  'cron' => '*/4 * * * *' # Run every 4 minutes
},

      # 'radact_job' => {
      #   'class' => 'RadactJob',
      #   'cron' => '* * * * *' # Run every minute

      # },

      'system_metrics_job' => {
        'class' => 'SystemMetricsJob',
        'cron' => '* * * * *' # Run every minute
      },




      # 'hotspot_expiration_job' => {
      #   'class' => 'HotspotExpirationJob',
      #   'cron' => '* * * * *' # Run every minute
      # },
      
      'hotspot_expiration_job' => {
  'class' => 'HotspotExpirationJob',
  'cron' => '*/4 * * * *'
}
      
    }

    Sidekiq.schedule = schedule
    Sidekiq::Scheduler.reload_schedule!
  end
end
