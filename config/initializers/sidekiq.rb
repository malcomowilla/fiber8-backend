# config/initializers/sidekiq.rb
require 'sidekiq'
require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0' }

  config.on(:startup) do
    schedule = {
      'subscription_expired_job' => {
        'class' => 'SubscriptionExpiredJob',
        'cron' => '* * * * *', # Every minute
        'queue' => 'default'
      },
      'router_ping_job' => {
        'class' => 'RouterPingJob',
        'cron' => '* * * * *',
        'queue' => 'default'
      },
      'hotspot_expiration_job' => {
        'class' => 'HotspotExpirationJob',
        'cron' => '*/4 * * * *',
        'queue' => 'default'
      }
    }

    Sidekiq.schedule = schedule
    Sidekiq::Scheduler.reload_schedule!
    Rails.logger.info "Loaded Sidekiq schedule: #{Sidekiq.schedule.keys}"
  end
end