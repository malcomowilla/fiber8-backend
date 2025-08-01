class BlockLoophole
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    forbidden_hosts = [
      /\A[a-z0-9-]+\.loophole\.site\z/i,
      /\Aeadb17b24faecde730f4d59914c23431\.loophole\.site\z/,
      /\A(?!127\.0\.0\.1)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\z/ # Block public IPs but allow localhost
    ]

    blocked_paths = [
      "/",                    # homepage
      "/rails/info",          # Rails default info
      "/rails/info/properties",
      "/rails/consoles",      # any default endpoints you want to secure
      %r{^/admin},            # optionally block your admin panel
      %r{^/internal}          # or any internal API endpoints
    ]

    host = request.host.to_s
    referer_host = URI.parse(request.referer).host rescue nil
    path = request.path

    is_forbidden_host = forbidden_hosts.any? { |regex| host =~ regex || referer_host =~ regex }
    is_blocked_path   = blocked_paths.any? { |p| p.is_a?(Regexp) ? path =~ p : path == p }

    if is_forbidden_host && is_blocked_path
      Rails.logger.warn("Blocked loophole access to: #{path}, host: #{host}, referer: #{request.referer}")
      return [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
    end

    @app.call(env)
  end
end
