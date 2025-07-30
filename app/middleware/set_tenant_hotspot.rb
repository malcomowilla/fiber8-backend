

class SetTenantHotspot
  def initialize(app)
    @app = app
  end

  def call(env)

    

    request = ActionDispatch::Request.new(env)
    
    Rails.logger.info "Skipping inactivity check for non-admin path: #{request.path.split('/').reject(&:empty?)}"


    admin_sensitive_paths = [
    
      # 'radius_settings',
      # 'get_ticket_settings',
      # 'get_tickets',
      # 'sms_provider_settings',
      'hotspot_settings',
      'hotspot_vouchers',
'hotspot_packages',
'hotspot_templates',
'get_active_hotspot_users',

      'update_hotspot_package',
      
# 'create_ticket',
# 'update_ticket',
      # 'login_with_hotspot_voucher',
      # 'calendar_events',
      # 'send_sms',
      
      # 'sign_in',
# 'wireguard',
#       'sign_in',



    ]





    path_segments = request.path.split('/').reject(&:empty?)
    target_path = path_segments[1] || path_segments[0] # Skip 'api' prefix

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
          error_message = "License expired for account #{account.subdomain}. Please renew your license for hotspot license."
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
  expired_hotspot = account.hotspot_plan&.expiry&.present? && account&.hotspot_plan&.expiry <= Time.current
  

  expired_hotspot
  end
end





