require 'sidekiq'
require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0' }

  config.on(:startup) do
    schedule = {
      'generate_invoice_job' => {
        'class' => 'GenerateInvoiceJob',
        'cron' => '* * * * *'
      },

      # 'rehydrate_wireguard_job' => {
      #   'class' => 'RehydrateWireguardJob',
      #   'cron' => '* * * * *'
      # },

      # 'rad_sessions_job' => {
      #   'class' => 'RadSessionsJob',
      #   'every' => ['20s'],
      #   'queue' => 'radacct'
      # },

      # 'generate_clients_conf_job' => {
      #   'class' => 'GenerateClientsConfJob',
      #   'cron' => '* * * * *'
      # },

      # 'online_stats_broadcast_job' => {
      #   'class' => 'OnlineStatsBroadcastJob',
      #   'cron' => '* * * * *'
      # },

      # 'restart_cloudflared_if_tunnel_missing_job' => {
      #   'class' => 'RestartCloudflaredIfTunnelMissingJob',
      #   'cron' => '* * * * *'
      # },

      # 'lock_account_job' => {
      #   'class' => 'LockAccountJob',
      #   'cron' => '*/2 * * * *'
      # },

      # 'hotspot_expiration_job' => {
      #   'class' => 'HotspotExpirationJob',
      #   'cron' => '* * * * *'
      # },

      # 'contention_ratio_job' => {
      #   'class' => 'ContentionRatioJob',
      #   'cron' => '* * * * *'
      # },

      # 'router_ping_job' => {
      #   'class' => 'RouterPingJob',
      #   'cron' => '* * * * *'
      # },

      # 'subscription_expiration_job' => {
      #   'class' => 'SubscriptionExpirationJob',
      #   'cron' => '* * * * *'
      # },

      # 'system_metrics_job' => {
      #   'class' => 'SystemMetricsJob',
      #   'cron' => '* * * * *'
      # },

      # 'company_id_job' => {
      #   'class' => 'CompanyIdJob',
      #   'cron' => '* * * * *'
      # },

      # 'inactivity_check_job' => {
      #   'class' => 'InactivityCheckJob',
      #   'cron' => '* * * * *'
      # }
    }

    Sidekiq.schedule = schedule
    Sidekiq::Scheduler.reload_schedule!
    Rails.logger.info("✅ Sidekiq schedule loaded: #{Sidekiq.schedule.keys.join(', ')}")
  end
end
