require_relative "boot"

require "rails/all"
require_relative '../app/middleware/set_tenant'





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


    puts("Loading cookies session store options")
    config.session_options = {
      httponly: true,
      same_site: "Lax",
      secure: false
    }
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # config/application.rb

# config.hosts = nil
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use SetTenant

    # puts("Loading cookies session store options")
    # config.session_store :cookie_store, key: '_fiber8backend_session', httponly: true, same_site: :none, secure: Rails.env.production?
# Use SameSite=Strict for all cookies to help protect against CSRF
config.action_dispatch.cookies_same_site_protection = :strict
  end
end
