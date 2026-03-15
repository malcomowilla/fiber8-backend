class Rack::Attack
  ### Configure Cache ###
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ## Throttle Login Attempts Per IP ###
  throttle('logins/ip', limit: 15, period: 1.minute) do |req|
    Rails.logger.warn "[Rack::Attack] Checking login attempt from IP: #{req.ip}" if req.path == '/api/sign_in' && req.post?
    req.ip if req.path == '/api/sign_in' && req.post?
  end

  ### Throttle Login Attempts Per Email ###
  # throttle('logins/email', limit: 5, period: 1.minute) do |req|
  #   if req.path == '/api/sign_in' && req.post?
  #     req.params['email'].to_s.downcase.strip.presence
  #   end
  # end



  throttle('logins/email', limit: 10, period: 40.seconds) do |req|
      #  Rails.logger.warn "[Rack::Attack] Checking login attempt from my IP: #{req.ip}" if req.path == '/api/sign_in' && req.post?
       body = JSON.parse(req.body.read) rescue {}
    if req.path == '/api/sign_in' && req.post?
      Rails.logger.warn "[Rack::Attack] Request params: #{body}"
      body['email'].to_s.downcase.gsub(/\s+/, "").presence
      # Rails.logger.warn "[Rack::Attack] Throttling email: #{email}" if email
    end
  end
  



  ### Logging to Debug if Requests are Throttled ###
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    Rails.logger.info "[Rack::Attack] Throttled request: #{payload[:request].ip} for #{payload[:request].path}"
  end




# Block suspicious paths
  blocklist("block suspicious paths") do |req|
    bad_paths = [
      "/.env",
      "/.env.production",
      "/.git",
      "/phpmyadmin",
      "/wp-admin",
      "dashboard",
      "/env",
      "/config",
      "/billing",
      "/swagger.json",
      "/v2/api-docs",
      "/src/config/.env",
      "/wp-login.php",
      "/wp-admin/install.php",
      "/wp-admin/upgrade.php",
      "/wp-admin/admin-ajax.php",
      "/wp-admin/admin-post.php",
      "/wp-admin/admin-ajax.php", 
      "/wp-admin/admin-post.php",
      "/wp-login.php",
      "/order",
      "/wp-admin/install.php",
      "/wp-admin/upgrade.php",
      "/wp-admin/admin-ajax.php", 
      "/api/user",
      "_internal/api/setup.php",
      "/.vscode/sftp.json",
      "/sftp.json",
      "/@vite/env",
      "/about",
      "/@vite/client",
      "/@vite/client/env",
      "/@vite/client/src/env.d.ts",
      "/@vite/client/dist",
      "/@vite/client/dist/env.d.ts",
      "/@vite/client/dist/index.html",
      "/@vite/client/dist/assets",
      "/server-status",
      "/console", 
      "/setup", 
      "/kyc/.env",
      "/www/.env",
      "/tests/.env",
      "/debug/default/view",
      "/trace.axd", 
      "/new/.env",
      "/src/config/.env",
      "/docker/.env",
      "/dev/.env",
      "/src/.env",
      "/prod/.env",
      "/bin",
      "/conf/.env"

    ]

    bad_paths.any? { |path| req.path.start_with?(path) }
  end

  # Block scanners by user agent
  blocklist("block scanners") do |req|
    req.user_agent =~ /(nikto|sqlmap|nmap|masscan|dirbuster)/i
  end

  # Rate limit requests
  throttle('req/ip', limit: 100, period: 1.minute) do |req|
    req.ip
  end


#   self.throttled_responder = lambda do |env|


# #     email = body['email' ].to_s.downcase.gsub(/\s+/, "").presence 
# # User.find_by(email: email).update(locked_account: true) 
# #     # Send an email notification if the email is available
# #     # if email.present?
# #     #   BlockedUserMailer.notify_block(email).deliver_later
# #     # end
# #     BlockedUserMailer.notify_block(email).deliver_now
# [429, { 'Content-Type' => 'application/json' }, [ { error: "Too many requests. Try again later." }.to_json.to_s ]]

#   end
end

