

class SetTenantPpoe 
  def initialize(app)
    @app = app
  end

  def call(env)

    

    request = ActionDispatch::Request.new(env)
    
    Rails.logger.info "Skipping inactivity check for non-admin path: #{request.path.split('/').reject(&:empty?)}"


    admin_sensitive_paths = [
    
#       'radius_settings',
#       # 'get_ticket_settings',
#       'all_sms',
#       'get_tickets',
#       'get_package',
#       'sms_settings',
#       'sms_provider_settings',

# 'get_all_admins',

'delete_subscriber',
# 'update_subscriber',
      # 'subscribers',
      # 'update_hotspot_package',
# 'router_settings',
      'update_package',
      'package',
      
# 'subscribers',
# 'total_subscribers',
# 'subscribers_offline',
# 'get_package',
# 'delete_user',

      # 'company_settings',
# 'create_router',
# 'logout',

      # 'login_with_hotspot_voucher',
'create_package',
#   'restart_service',
#       'block_service',
#       'client_leads',
#       'calendar_events',
#       'send_sms',
      
#       'reboot_router',
      # 'wireguard',
      # 'sign_in',
      




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

    host = request.headers['X-Subdomain'] 
    if host.present?
      Rails.logger.info "Setting tenant for host: #{host}"

      begin
        # Find or create the account based on the subdomain
        account = Account.find_or_create_by!(subdomain: host)
        ActsAsTenant.current_tenant = account
        Rails.logger.info "Tenant set to: #{account.subdomain}"



        # Check for expired plans
        if license_expired?(account)
          error_message = "License expired for account #{account.subdomain}. Please renew your license for pppoe license"
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
    # expired_pppoe = account.pp_poe_plan.present? && account.pp_poe_plan.expiry <= Time.current
    
    # expired_hotspot = account.hotspot_plan.present? && account.hotspot_plan.expiry <= Time.current

    # expired_pppoe || expired_hotspot
     expired_pppoe = account.pp_poe_plan&.expiry&.present? && account&.pp_poe_plan&.expiry >= Time.current

  expired_pppoe
  end
end




