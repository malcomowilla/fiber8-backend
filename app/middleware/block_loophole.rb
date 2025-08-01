class BlockLoophole
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    forbidden_hosts = [
      /\A[a-z0-9-]+\.loophole\.site\z/i,
      /\Aeadb17b24faecde730f4d59914c23431\.loophole\.site\z/,
      /\A(?!127\.0\.0\.1)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\z/ # exclude 127.0.0.1
    ]

    host = request.host.to_s
    referer_host = URI.parse(request.referer).host rescue nil

    if forbidden_hosts.any? { |regex| host =~ regex || referer_host =~ regex }
      Rails.logger.warn("Blocked loophole request: #{host}, referer: #{request.referer}")
      return [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
    end

    @app.call(env)
  end
end
