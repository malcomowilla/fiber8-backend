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
  
#     if host = request.headers['X-Subdomain']
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




# class SetTenant
#   def initialize(app)
#     @app = app
#   end

#   def call(env)
#     request = ActionDispatch::Request.new(env)
#     Rails.logger.info "Request headers: #{request.headers.to_h}" # Log all headers

#     # Extract subdomain from the custom header or use default logic
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

    Rails.logger.info "Request object domain: #{request.domain}"
    Rails.logger.info "Request object subdomain: #{request.subdomain}"

    # Retrieve subdomain from custom header
    host = request.headers['X-Subdomain']
    Rails.logger.info "Subdomain from header: #{host}"

    if host.present?
      Rails.logger.info "Setting tenant for host: #{host}"

      begin
        # Find or create the account based on the subdomain
        account = Account.find_or_create_by!(subdomain: host)
        ActsAsTenant.current_tenant = account
        Rails.logger.info "Tenant set to: #{account.subdomain}"
      rescue StandardError => e
        # Log the error and continue execution
        Rails.logger.error "Failed to set tenant for host #{host}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    else
      Rails.logger.warn "No subdomain found in the request headers."
    end

    # Continue to the next middleware or application
    @app.call(env)
  end
end





# class SetTenant
#   def initialize(app)
#     @app = app
#   end

#   # def call(env)
#   #   request = ActionDispatch::Request.new(env)
#   #   # Rails.logger.info "Request headers: #{request.headers.to_h}" # Log all headers
#   #   host = request.headers['X-Subdomain']
    
#   #   # Rails.logger.info "Subdomain from header: #{host}"

#   #   if host.present?
#   #     Rails.logger.info "Setting tenant for host: #{host}"
    
#   #     begin
#   #       # Find or create the account based on the subdomain
#   #       account = Account.find_or_create_by(subdomain: host)
    
#   #       # Ensure the account is valid and has a subdomain
#   #       if account.subdomain.present?
#   #         ActsAsTenant.current_tenant = account
#   #       else
#   #         Rails.logger.error "Invalid account or empty subdomain for host: #{host}"
#   #         # Handle the error case (e.g., raise an exception or return an error response)
#   #       end
#   #     rescue => e
#   #       Rails.logger.error "Error setting tenant for host: #{host}. Error: #{e.message}"
#   #       # Handle the exception (e.g., raise an exception or return an error response)
#   #     end
#   #   else
#   #     Rails.logger.warn "Empty or missing subdomain in request headers"
#   #     # Handle the case where the subdomain is missing (e.g., raise an exception or return an error response)
#   #   end

#   #   # Call the next middleware or application
#   #   @app.call(env)
#   # end
#   # 
#   #
#   #
#   #



#   # def call(env)
#   #   request = ActionDispatch::Request.new(env)
#   #   Rails.logger.info "Request object: #{request.inspect}"

#   #   if host = request.headers['X-Subdomain']
#   #     Rails.logger.info "Setting tenant for host: #{host}"
#   #     begin
#   #       account = Account.find_or_create_by(subdomain: host)
#   #       ActsAsTenant.current_tenant = account
#   #     rescue => e
#   #       Rails.logger.error "Failed to set tenant for host #{host}: #{e.message}"
#   #       # Continue with the request even if tenant setting fails
#   #     end
#   #   else
#   #     Rails.logger.info "Request object: #{request.inspect}"

#   #     Rails.logger.info "No X-Subdomain header found, skipping tenant setup"
#   #   end

#   #   @app.call(env)
#   # ensure
#   #   # Clear the tenant after the request to prevent leaking between requests
#   #   # ActsAsTenant.current_tenant = nil
#   # end




# end