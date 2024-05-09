class ApplicationController < ActionController::Base

    set_current_tenant_through_filter

    before_action :set_tenant
    # set_current_tenant_by_subdomain_or_domain(:account, :subdomain, :domain)

    # before_action :authorized
    # before_action :current_user
    include ActionController::Cookies

    # protect_from_forgery with: :exception
   


    skip_before_action :verify_authenticity_token

    def set_tenant
        @account = Account.find_or_create_by( domain:request.domain, subdomain: request.subdomain)
      
        set_current_tenant(@account)
      
      end

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






  
def current_user
    # render json: { user: UserSerializer.new(current_user) }, status: :accepted
    @user = User.find_by(id:session[:user_id])
      
    
              
    end







end

