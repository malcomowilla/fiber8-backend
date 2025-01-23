class ApplicationController < ActionController::Base

    set_current_tenant_through_filter

    # before_action :set_tenant
    # set_current_tenant_by_subdomain_or_domain(:account, :subdomain, :domain)




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






  
    # render json: { user: UserSerializer.new(current_user) }, status: :accepted
    # @user = User.find_by(id: session[:user_id])
      
    
      


    def current_system_admin
      @current_user ||= begin
        token = cookies.encrypted.signed[:jwt_user]
        if token  
          begin
            decoded_token = JWT.decode(token,  ENV['JWT_SECRET'], true, algorithm: 'HS256')
          user_id = decoded_token[0]['user_id']
          @current_user = User.find_by(id: user_id)
            return @current_user if @current_user
          rescue JWT::DecodeError, JWT::ExpiredSignature => e
            Rails.logger.error "JWT Decode Error: #{e}"
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
              Rails.logger.error "JWT Decode Error: #{e}"
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

