class Maintenance
  ALLOWED_PATHS = %w[
    /api/maintenance_status
    /api/logout
    /system-admin-login
    /favicon.ico
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Always allow admin login + maintenance status endpoints
    return @app.call(env) if ALLOWED_PATHS.any? { |p| request.path.start_with?(p) }

    subdomain = request.host.split('.').first
    account   = Account.find_by(subdomain: subdomain)

    if account
      setting = MaintenanceSetting.find_by(enabled: true)
      if setting
        # Auto-disable if time has passed
        if setting.until_time.present? && setting.until_time < Time.current
          setting.update(enabled: false)
        else
          # API request → return 503 JSON
          if request.path.start_with?('/api/')
            return [
              503,
              { 'Content-Type' => 'application/json' },
              [{ error: 'System under maintenance', until: setting.until_time&.iso8601 }.to_json],
            ]
          end
          # For non-API requests React handles it via MaintenanceGate
          # so just let it through — the JS will show the screen
        end
      end
    end

    @app.call(env)
  end
end