class BlockedUser
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)
    req = Rack::Request.new(env)
    ip = req.ip


    # host = req.headers['X-Subdomain']
    # @account = Account.find_by(subdomain: host)
     Rails.logger.info "Final blocked status: #{status} - Expected: 429"

    if status == 429 # If request is throttled
      req = Rack::Request.new(env)
      ip = req.ip

      @current_account=ActsAsTenant.current_tenant 
      EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])
  
  
      BlockedUserMailer.notify_block(ip).deliver_now

      unless Rails.cache.read("blocked_ip:#{ip}") # Prevent duplicate emails
        Rails.cache.write("blocked_ip:#{ip}", true, expires_in: 1.hour)
        BlockedUserMailer.notify_block(ip).deliver_now
      end
    end

    [status, headers, response]
  end
end
