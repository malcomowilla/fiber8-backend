class SessionsController < ApplicationController

   before_action :set_tenant 
#    before_action :check_expiry
    # skip_before_action :authorized, only: [:create]


    # def create
    #     user = User.find_by(email: params[:email])
    
    # if user && user.authenticate(params[:password])

            
    #         session[:user_id] = user.id
            

    #         render json: user, status: :created
            
    #     else
    #         render json: {error: 'Invalid username or password'}, status: :unauthorized
    #     end
    # end
    
# def check_expiry
#     if Time.current - session[:activity] > 1.minutes

#       session.clear
#       render json: {error: 'u have reached ur limit'}, status: :unauthorized
#     else

#         session[:activity] = Time.current

#     end
# end

    # def show
    #     user = User.find_by(id:session[:user_id])
    #     if user
    #       render json: user
    #        else
    #           render json: { error: "Not authorized" }, status: :unauthorized
    #           end
    
              
    # end
    
    def destroy
        session.delete :user_id
        head :no_content
    end


    # def create
    #     @user = User.find_by(email: params[:email])
    #     #User#authenticate comes from BCrypt
    #     if @user && @user.authenticate(params[:password])
    #     # encode token comes from ApplicationController
    #     # token = encode_token({ user_id: @user.id })
    #     session[:user_id] = @user.id

        
    #     # render json: { user: UserSerializer.new(@user), jwt: token }, status: :accepted
    #     render json: {user: UserSerializer.new(@user) }, status: :accepted
    #     else
    #     render json: { message: 'Invalid username or password' }, status: :unauthorized
    #     end
    #     end

    def create

        @user = User.find_by(email: params[:email])

        if @user&.authenticate(params[:password])
            set_current_tenant(@user.account)
            session[:user_id] = @user.id
                
                
            render json: { user: @user }, status: :accepted
          
        else
          render json: { message: 'Invalid username or password' }, status: :unauthorized
        end
      end
    
    private

        # def user_params
        #     params.permit( :password, :email)
        # end
        def user_login_params
            # params { user: {username: 'Chandler Bing', password: 'hi' } }
            params.require(:user).permit(:email, :password)
            end

        

            def authorized
                render json: { message: 'Please log in' }, status: :unauthorized unless session.include? :user_id
                end
                

end
