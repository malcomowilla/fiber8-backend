class PasswordResetsController < ApplicationController

    set_current_tenant_through_filter

    before_action :set_tenant






    def set_tenant
        host = request.headers['X-Subdomain']
        @account = Account.find_by(subdomain: host)
        @current_account =ActsAsTenant.current_tenant 
        EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])
        # EmailSystemAdmin.configure(@current_account, current_system_admin)
      Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
      
        # set_current_tenant(@account)
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Invalid tenant' }, status: :not_found
      
        
      end






   def create
    @user = User.find_by(email: params[:email])
   
    if @user
        token = SecureRandom.urlsafe_base64
        @user.update(
          password_reset_token: token,
          password_reset_sent_at: Time.current
        )

        reset_subdomain = request.headers['X-Subdomain']


    PasswordMailer.reset(@user, reset_subdomain).deliver_now
   
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




 def reset_password_confirmation
    @user = User.find_by(password_reset_token: params[:token])
  
    return render json: { error: 'Invalid token' }, status: :unauthorized unless @user
  
    # Check token expiry (5 minutes)
    if @user.password_reset_sent_at < 5.minutes.ago
      return render json: { error: 'Token has expired' }, status: :unauthorized
    end
  
    password = params[:password]
    password_confirmation = params[:password_confirmation]
  
    # Check if password and confirmation match
    unless password.present? && password == password_confirmation
      return render json: { error: 'Passwords do not match' }, status: :unprocessable_entity
    end
  
    if @user.update(password: password, password_confirmation: password_confirmation)
      # Clear token after successful reset
      @user.update(password_reset_token: nil, password_reset_sent_at: nil)
  
      render json: { message: 'Password reset successfully. You can now log in.' }, status: :ok
    else
      render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
    end
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
