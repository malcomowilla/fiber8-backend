require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
  # config.active_job.queue_adapter = :sidekiq



  def self.current_cloudflare_url
    @current_cloudflare_url ||= begin
     
        # For development/staging - parse from cloudflared logs
        logs = `journalctl -u cloudflared -n 100 --no-pager --reverse`
        match = logs.match(/https:\/\/([a-z0-9-]+\.trycloudflare\.com)/)
        match ? match[1] : 'default.trycloudflare.com'
      
    end
  end

  Rails.application.routes.default_url_options[:host] = current_cloudflare_url


  # Rails.application.routes.default_url_options[:host] = 'solving-choice-dutch-utah.trycloudflare.com'
  # Rails.application.routes.default_url_options[:host] = 'localhost:5173'

#   Rails.application.routes.default_url_options = {
#   host: '102.221.35.116',
#   protocol: 'http'
# }
  config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address:              'smtp.gmail.com',
  port:                 465,
  domain:               'captive-portal.onrender.com/',
  user_name:            'malcomowilla@gmail.com',
  password:             ENV['GOOGLE_APP_PASSWORD'],
  authentication:       'plain',
  enable_starttls_auto: true
}
  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true
  # Rails.application.config.action_mailer.delivery_method = :mailtrap
  # Rails.application.config.action_mailer.mailtrap_settings = {
  #   api_key: 'd848f326f33a7aa8db359e399fd7c510'
  # }
  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  # config.hosts << "solving-choice-dutch-utah.trycloudflare.com" 
     config.hosts << current_cloudflare_url

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise



  # Store files locally.
config.active_storage.service = :local

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = false

  # config.force_ssl = true


end
