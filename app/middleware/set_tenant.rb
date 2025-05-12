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




# class SetTenant
#   def initialize(app)
#     @app = app
#   end

#   def call(env)

#     Account.find_each do |tenant|
#       ActsAsTenant.with_tenant(tenant) do

#     request = ActionDispatch::Request.new(env)
# # Rails.logger.info " emailin middleware #{request.email}"
#     # Rails.logger.info "Request object domain: #{request.domain}"
#     # Rails.logger.info "Request object subdomain: #{request.subdomain}"

#     # Retrieve subdomain from custom header
#     host = request.headers['X-Subdomain']
#     Rails.logger.info "Subdomain from header: #{host}"


#     if host.present?
#       Rails.logger.info "Setting tenant for host: #{host}"

#       begin
#         # Find or create the account based on the subdomain
#         account = Account.find_or_create_by!(subdomain: host)
#         ActsAsTenant.current_tenant = account
#         # Rails.logger.info "Tenant set to: #{account.subdomain}"
#         Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
#         check_expired_plans(account)
#       rescue StandardError => e
#         # Log the error and continue execution
#         Rails.logger.error "Failed to set tenant for host #{host}: #{e.message}"
#         Rails.logger.error e.backtrace.join("\n")
#       end
#     else
#       Rails.logger.warn "No subdomain found in the request headers."
#     end

#     # Continue to the next middleware or application
#     @app.call(env)
#   end
# end
# end



# private


# def check_expired_plans(account)
#   # Check PpPoePlan for expired licenses
#   expired_pppoe = account.pppoe_plan.where('expiry <= ?', Time.current)
#   expired_hotspot = account.hotspot_plan.where('expiry <= ?', Time.current)

#   if expired_pppoe.exists? || expired_hotspot.exists?
#     error_message = "License expired for account #{account.subdomain}. Please renew your license."
#     Rails.logger.error error_message
    
#     # You can either raise an error or modify the response
#     # Option 1: Raise an error
#     # raise StandardError, error_message
    
#     # Option 2: Return an error response
#     return [402, { 'Content-Type' => 'application/json' }, [{ error: error_message }.to_json]]
#   end
# end
# end










class SetTenant
  def initialize(app)
    @app = app
  end

  def call(env)

    # Rails.logger.auto_flushing = true
    

    request = ActionDispatch::Request.new(env)
    # Rails.logger.info "Skipping inactivity check for non-admin path: #{request.path.split('/').reject(&:empty?)}"

    host = request.headers['X-Subdomain'] || request.subdomain.presence || 'localhost'
    # Rails.logger.info "Subdomain from header: #{host}"
    Rails.logger.info "Skipping inactivity check for non-admin path: #{request.path.split('/').reject(&:empty?)}"



    # Rails.logger.info "Skipping inactivity check for non-admin path: #{request.path}"

  
  
  
  
    # get "up" => "rails/health#show", as: :rails_health_check
    # Defines the root path route ("/")
    # root "posts#index"
  
  
  
    

    admin_sensitive_paths = [
    
      'radius_settings',
      'get_ticket_settings',
      'all_sms',
      'get_tickets',
      'sms_settings',
      'sms_provider_settings',


'delete_subscriber/:id',
'update_subscriber',
'delete_hotspot_package/:id',
      'subscribers/import',
      'update_hotspot_package/:id',
'router_settings',
      'update_package/:id',
      'package/:id',
      

'delete_user/:id',
'update_router/:id',
'delete_router/:id',
      'company_settings',
'create_router',
'logout',
'create_ticket',
'update_ticket',
      'login_with_hotspot_voucher',
'create_package',
  'restart_service',
      'block_service',
      'send_sms',
      
      'reboot_router',
      'wireguard/generate_config',
      'sign_in',
      'wireguard/generate_config'




    ]





    path_segments = request.path.split('/').reject(&:empty?)
    target_path = path_segments[1] # Skip 'api' prefix

    # Rails.logger.info "Skipping inactivity check for non-admin path target path: #{request.path.split('/').reject(&:empty?)[1]}"
    #  Rails.logger.info "Skipping inactivity check for non-admin path2: #{request.path.split('/').reject(&:empty?)}"


    unless admin_sensitive_paths.include?(target_path)
      Rails.logger.info "Request object: #{request.inspect}"

      Rails.logger.info "Skipping inactivity check for non-admin path3: #{target_path}"
      return @app.call(env)
    end

    if host.present?
      Rails.logger.info "Setting tenant for host: #{host}"

      begin
        # Find or create the account based on the subdomain
        account = Account.find_or_create_by!(subdomain: host)
        ActsAsTenant.current_tenant = account
        Rails.logger.info "Tenant set to: #{account.subdomain}"



        # Check for expired plans
        if license_expired?(account)
          error_message = "License expired for account #{account.subdomain}. Please renew your license."
          Rails.logger.error error_message
          return [402, { 'Content-Type' => 'application/json' }, [{ error: error_message }.to_json]]
        end

      rescue StandardError => e
        Rails.logger.error "Failed to set tenant for host #{host}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        return [500, { 'Content-Type' => 'application/json' }, [{ error: "Internal server error" }.to_json]]
      end
    else
      Rails.logger.warn "No subdomain found in the request."
      return [400, { 'Content-Type' => 'application/json' }, [{ error: "Subdomain missing from request" }.to_json]]
    end

    # Continue to the next middleware or application
    @app.call(env)
  end

  private

  def license_expired?(account)
    # Check if any plans are expired
    expired_pppoe = account.pp_poe_plan.present? && account.pp_poe_plan.expiry <= Time.current
    
    expired_hotspot = account.hotspot_plan.present? && account.hotspot_plan.expiry <= Time.current

    expired_pppoe || expired_hotspot
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