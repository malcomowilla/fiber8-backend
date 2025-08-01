class BlockLoophole
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    forbidden_hosts = [
      /.*\.loophole\.site$/,
      /eadb17b24faecde730f4d59914c23431\.loophole\.site/,
      /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ # match direct IP
    ]

    if forbidden_hosts.any? { |regex| request.host =~ regex || request.referer.to_s =~ regex }
      Rails.logger.warn("Blocked loophole request: #{request.host}, referer: #{request.referer}")
      return [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
    end

    @app.call(env)
  end
end
