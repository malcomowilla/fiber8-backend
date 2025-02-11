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

  ### Custom Throttle Response ###
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

