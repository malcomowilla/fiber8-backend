class PasswordResetsController < ApplicationController

def 
    new
    
end

   def create
    @user = User.find_by(email: params[:email])

    if @user
        
    PasswordMailer.with(user: @user).reset.deliver_now
    render json: {message: "Nimekutumia email ya kureset password cheki gmail account yako!!"}, status: :ok
    else
        render json: {error: 'Hatuna Email Yako Bro'}, status: :unprocessable_entity
    end

   end



   def edit
    @user = User.find_signed(params[:token], purpose: "password_reset")
    # Add any additional logic you need for the edit action here
   rescue ActiveSupport::MessageVerifier::InvalidSignature

    flash[:alert] = "The token has expired. Please try again."
    redirect_to root_url  
 end


def update
    @user = User.find_signed(params[:token], purpose: "password_reset")
    
if @user.update(password_params)
    flash[:alert] = "Your Password Was reset Sucessfully"
    redirect_to "http://localhost:5173/signin" # Redirect to the login page of your frontend app

else
    render :edit
end
end

private

def password_params
    params.require(:user).permit(:password, :password_confirmation)
end


  end
