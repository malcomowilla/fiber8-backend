# class SetTenant
#   def initialize(app)
#     @app = app
#   end

#   def call(env)
#     request = ActionDispatch::Request.new(env)
#     Rails.logger.info "Request object domain: #{request.domain}"
#     Rails.logger.info "Request object subdomain: #{request.subdomain}"
  
#     # Read the subdomain from the custom header
#     host = request.headers['X-Subdomain']
#     Rails.logger.info "Subdomain from header: #{host}"
  
#     if host.present?
#       Rails.logger.info "Setting tenant for host: #{host}"
  
#       begin
#         # Find or create the account based on the subdomain
#         account = Account.find_or_create_by(subdomain: host)
#         ActsAsTenant.current_tenant = account
#         Rails.logger.info "Tenant set to: #{account.subdomain}"
#       rescue => e
#         # Log the error and continue execution
#         Rails.logger.error "Failed to set tenant for host #{host}: #{e.message}"
#         Rails.logger.error e.backtrace.join("\n") # Log the full backtrace for debugging
#       end
#     else
#       Rails.logger.warn "No subdomain found in the request headers."
#     end
  
#     # Call the next middleware or application
#     @app.call(env)
#   end
# end









class SetTenant
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    Rails.logger.info "Request headers: #{request.headers.to_h}" # Log all headers
    host = request.headers['X-Subdomain']
    Rails.logger.info "Subdomain from header: #{host}"

    if host.present?
      Rails.logger.info "Setting tenant for host: #{host}"

      begin
        # Find or create the account based on the subdomain
        account = Account.find_or_create_by(subdomain: host)
        ActsAsTenant.current_tenant = account
        Rails.logger.info "Tenant set to: #{account.subdomain}"
      rescue => e
        # Log the error and continue execution
        Rails.logger.error "Failed to set tenant for host #{host}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n") # Log the full backtrace for debugging
      end
    else
      Rails.logger.warn "No subdomain found in the request headers."
    end

    # Call the next middleware or application
    @app.call(env)
  end
end