class ApplicationController < ActionController::Base

    set_current_tenant_through_filter



    rescue_from CanCan::AccessDenied do |exception|
      render json: { error: "Access Denied: #{exception.message}" }, status: :forbidden
    end

    
    before_action :set_tenant
    # set_current_tenant_by_subdomain_or_domain(:account, :subdomain, :domain)

# before_action :set_current_tenant


    # before_action :authorized
    # before_action :current_user
    include ActionController::Cookies

    # protect_from_forgery with: :exception
   



    skip_before_action :verify_authenticity_token

#     def set_tenant
#         @account = Account.find_or_create_by(domain:request.domain, subdomain: request.subdomain)
      
# #i am writing this line of code for testing 
#         set_current_tenant(@account)
      
#       end

    # def current_user
    #     if session[:user_id]
    #       Current.user = User.find_by(id: session[:user_id])
        
    #     end
    
# end


# def authorized
#     render json: { message: 'Please log in' }, status: :unauthorized unless session.include? :user_id
#     end








# before_action :authorized
# def encode_token(payload)
# # should store secret in env variable
# JWT.encode(payload, 'my_s3cr3t')
# end
# def auth_header
# # { Authorization: 'Bearer <token>' }
# request.headers['Authorization']
# end
# def decoded_token
# if auth_header
# token = auth_header.split(' ')[1]
# # header: { 'Authorization': 'Bearer <token>' }
# begin
# JWT.decode(token, 'my_s3cr3t', true, algorithm: 'HS256')
# rescue JWT::DecodeError
# nil
# end
# end


# end
# def current_user
# if decoded_token
# user_id = decoded_token[0]['user_id']
# @user = User.find_by(id: user_id)
# end
# end


# def logged_in?
# !!current_user
# end
# 








# def set_email
      
  
#   @current_account=ActsAsTenant.current_tenant 
#   EmailConfiguration.configure(@current_account)
#   # Define the directory for storing QR codes
  
# end






def set_tenant
  host = request.headers['X-Subdomain']
  @account = Account.find_by(subdomain: host)
  @current_account=ActsAsTenant.current_tenant 
  EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])
  # EmailSystemAdmin.configure(@current_account, current_system_admin)
Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"

  # set_current_tenant(@account)
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Invalid tenant' }, status: :not_found

  
end



  
    # render json: { user: UserSerializer.new(current_user) }, status: :accepted
    # @user = User.find_by(id: session[:user_id])
      
    
      


    def current_system_admin
      # byebug
      @current_sys_admin ||= begin
        token = cookies.encrypted.signed[:jwt_system_admin]
        if token  
          begin
            decoded_token = JWT.decode(token,  ENV['JWT_SECRET_KEY'], 
            true, algorithm: 'HS256')
            system_admin_id = decoded_token[0]['system_admin_id']
          @current_system_admin = SystemAdmin.find_by(id: system_admin_id)
            return @current_system_admin if @current_system_admin
          rescue JWT::DecodeError, JWT::ExpiredSignature => e
            cookies.delete(:jwt_system_admin)
            Rails.logger.error "JWT Decode Error system admin: #{e}"
            render json: { error: 'Unauthorized' }, status: :unauthorized
          end
        end
        nil
      end
           
  end











    def current_user
        @current_user ||= begin
          token = cookies.encrypted.signed[:jwt_user]
          if token  
            begin
              decoded_token = JWT.decode(token,  ENV['JWT_SECRET'], true, algorithm: 'HS256')
            user_id = decoded_token[0]['user_id']
            @current_user = User.find_by(id: user_id)
              return @current_user if @current_user
            rescue JWT::DecodeError, JWT::ExpiredSignature => e
              cookies.delete(:jwt_user)
              Rails.logger.error "JWT Decode Error super admin: #{e}"
              render json: { error: 'Unauthorized' }, status: :unauthorized
            end
          end
          nil
        end
             
    end


    def current_user_ability
      if current_user.present?
        @current_ability ||= Ability.new(current_user)
      else
        raise CanCan::AccessDenied
      end
    end




end

