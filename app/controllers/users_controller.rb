  class UsersController < ApplicationController

    rescue_from ActiveRecord::RecordInvalid, with: :creation_error 

    # def set_current_tenant
    #   # Extract subdomain and domain from request
    #   subdomain = request.subdomain
    #   domain = request.domain
    
    #   # Debugging: Output extracted subdomain and domain
    #   puts "Subdomain: #{subdomain}, Domain: #{domain}"
      
    #   # Check if subdomain or domain is present and set current tenant accordingly
    #   if subdomain.present?
    #     set_current_tenant_by_subdomain_or_domain(:account, subdomain, domain)
    #   else
    #     # Debugging: Output error if subdomain is not present
    #     puts "No subdomain detected"
    #   end
    # end
    
    def auto_timeout
      2.minutes
    end
    
    def profile
      # render json: { user: UserSerializer.new(current_user) }, status: :accepted
          if current_user
             render json: current_user, serializer: UserSerializer, status: :ok
                     else
                      render json: { error: "Please Login" }, status: :unauthorized

               end
      
                
      end
        # def create_users
        #   user = User.create!(user_params)
        #   session[:user_id] = user.id
        #        render json: user, status: :created 
      
        # end




def create_users
   # You can modify this to create the account with the appropriate details
   
    @user = User.create(user_params)
    
  if @user.valid?
    # session[:account_id] =  @account.id
    render json: { user: UserSerializer.new(@user) }, status: :created
  else
    render json: { errors: @user.errors }, status: :unprocessable_entity
  end
end
      private


        def user_params
          params.permit(:email, :password, :password_confirmation, :username)
        end
    
        def creation_error(e) 
            render json: {errors: e.record.errors}, status: :unprocessable_entity
        end

        # def require_login
        #   unless session.include? :user_id
        #     render json: { error: "Not authorized" }, status: :unauthorized
        #   end
        # end



    end
    
    

