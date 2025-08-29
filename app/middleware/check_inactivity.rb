

class CheckInactivity
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    # Rails.logger.info "current tenant in middleware#{ActsAsTenant.current_tenant}"


    # Skip WebSocket connections
    
    


    admin_sensitive_paths = [
      'radius_settings',
      'get_ticket_settings',
      'all_sms',
      'get_tickets',
      'sms_settings',
      'sms_provider_settings',
'delete_subscriber/:id',
'setup_google_authenticator',
'update_subscriber',
'delete_hotspot_package/:id',
      'subscribers/import',
      'update_hotspot_package/:id',
'router_settings',
      'update_package/:id',
      'package/:id',
  'routers',
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
      'nodes',
      'reboot_router',
      'wireguard/generate_config',
      'user_groups',
      'wireguard/generate_config',
      'total_subscribers',
      'saved_sms_settings',
      'get_hotspot_settings',
      'update_profile',
      'delete_passkey',
      'get_package',
      'get_company_settings',
      'ip_networks',
      'client_leads',
      'get_all_admins',
      'subscribers',
      'hotspot_vouchers',
      'hotspot_settings',
      'get_tickets',
      'subscriber_settings',
      'hotspot_mpesa_settings',
      'saved_hotspot_mpesa_settings',
      'license_settings',
      'sms_templates',
      'admin_settings',
      'subscriptions',
      'registration_stats'
    ]


    path_segments = request.path.split('/').reject(&:empty?)
    target_path = path_segments[1] # Skip 'api' prefix



    unless admin_sensitive_paths.include?(target_path)
      Rails.logger.info "Request object: #{request.inspect}"

      Rails.logger.info "Skipping inactivity check for -admin path: #{target_path}"
      return @app.call(env)
    end
    Rails.logger.info "Request object: #{request.inspect}"

    Rails.logger.info "Checking inactivity for admin path: #{request.path}"

    # @account = Account.find_or_create_by(subdomain: request.headers['X-Original-Host'])
    # ActsAsTenant.current_tenant = @account

    token = request.cookie_jar.encrypted.signed[:jwt_user]
    
    if token
      begin
        decoded_token = JWT.decode(token,  ENV['JWT_SECRET'], true, algorithm: 'HS256')
        user_id = decoded_token[0]['user_id']

        if user_id
          admin = User.find_by(id: user_id)
          if admin
            admin_settings = AdminSetting.first
            
            if admin_settings
              # admin.update_columns(
              #   enable_inactivity_check: admin_settings.check_is_inactive == true,
              #   enable_inactivity_check_hours: admin_settings.check_is_inactivehrs == true,
              #   enable_inactivity_check_minutes: admin_settings.check_is_inactiveminutes == true
              # )
               
              

                  if admin_settings.check_is_inactive == true && admin.inactive == true
                Rails.logger.info "Inactivity check triggered for admin: #{admin.id}"
                # Clear the JWT cookie
                request.cookie_jar.delete(:jwt_user)
                        admin.update(status: 'inactive')

                response = Rack::Response.new
                response.status = 401
                response.set_header('Content-Type', 'application/json')
                response.set_header('X-Session-Expired', 'true')
                response.write({ 
                  error: 'Account inactive, please log in again',
                  code: 'SESSION_EXPIRED'
                }.to_json)
                
                return response.finish
              end
            end
          end
        end
      rescue JWT::DecodeError => e
        Rails.logger.error "JWT decode error: #{e.message}"
        request.cookie_jar.delete(:jwt_user)
        return [401, { 'Content-Type' => 'application/json' }, [{ error: 'Invalid or expired token' }.to_json]]
      end
    end

    @app.call(env)
  end
end



