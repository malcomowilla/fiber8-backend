require_relative "boot"

require "rails/all"
require_relative '../app/middleware/set_tenant'
require_relative '../app/middleware/check_inactivity'
# require_relative '../app/middleware/blocked_user'






# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
# Load .env file in development and test environments
if Rails.env.development? || Rails.env.test?
  Dotenv::Rails.load
end

module Fiber8backend
  class Application < Rails::Application
    # config.session_store :cookie_store, key: '_hue_session', domain: :all
    # puts("Loading cookies session store KEY")
    # config.middleware.use Rack::Attack
    # config.middleware.use BlockedUser
    # 



    def self.current_cloudflare_url
      @current_cloudflare_url ||= begin
       
          # For development/staging - parse from cloudflared logs
          logs = `journalctl -u cloudflared -n 100 --no-pager --reverse` 
          match = logs.match(/https:\/\/([a-z0-9-]+\.trycloudflare\.com)/)
          match ? match[1] : 'default.trycloudflare.com'
        
      end
    end

    Rails.application.config.middleware.delete Rack::Attack

config.middleware.use SetTenant
config.middleware.use CheckInactivity

# config.hosts << ".ngrok-free.app" 
    puts("Loading cookies session store options")
    config.session_options = {
      httponly: true,
      same_site: "Lax",
      secure: false
    }
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1
    config.time_zone = 'Africa/Nairobi'

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))
    # config.active_job.queue_adapter = :sidekiq
    # Configuration for the application, engines, and railties goes here.
    config.active_job.queue_adapter = :async

    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # config/application.rb
    # config.force_ssl = true
    # Rails.application.routes.default_url_options[:host] = 'solving-choice-dutch-utah.trycloudflare.com'
    config.hosts << current_cloudflare_url
    Rails.application.routes.default_url_options[:host] = current_cloudflare_url
# config.hosts = nil
    config.middleware.use ActionDispatch::Cookies
    # puts("Loading cookies session store options")
    # config.session_store :cookie_store, key: '_fiber8backend_session', httponly: true, same_site: :none, secure: Rails.env.production?
# Use SameSite=Strict for all cookies to help protect against CSRF
config.action_dispatch.cookies_same_site_protection = :strict
# config.hosts << "solving-choice-dutch-utah.trycloudflare.com" 
  end
end
