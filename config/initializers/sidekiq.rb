# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
    config.on(:startup) do
      Sidekiq.schedule = {
        'mikrotik_job' => {
          'class' => 'MikrotikJob',
          'cron' => '*/1 * * * * *' # Run every 2 seconds
        }
      }
      Sidekiq::Scheduler.reload_schedule!
    end
  end
  