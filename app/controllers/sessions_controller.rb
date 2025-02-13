class SessionsController < ApplicationController
  

  set_current_tenant_through_filter
before_action :set_tenant
# before_action :throttle_login


# rate_limit to: 10, within: 3.minutes, only: :create, with: -> { 
#   redirect_to "http://localhost:5173/login" # Change this to your React login page URL
# }

rate_limit to: 20, within: 5.minutes, only: :create, with: -> { 
  # Find the user by email (you need to get it from params)
  user = User.find_by(email: params[:email])
  
  # Lock the account if the user exists
  user.update(locked_account: true, locked_at: Time.current) if user.present?

  # Return JSON response
  render json: { redirect: "http://localhost:5173/account-locked" }, status: :too_many_requests 
}




def throttle_login
  ip = request.remote_ip
  key = "failed_logins:#{ip}"

  count = Rails.cache.read(key).to_i

  if count >= 20  # Allow only 5 login attempts
    render json: { error: "Too many login attempts. Try again later." }, status: :too_many_requests
    return
  end

  Rails.cache.write(key, count + 1, expires_in: 1.minutes) # Lockout for 5 minutes
end










def set_tenant

  host = request.headers['X-Subdomain']
  @account = Account.find_by(subdomain: host)


  set_current_tenant(@account)
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Invalid tenant' }, status: :not_found

  
end
# require 'webauthn'

#    before_action :set_tenant 
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
    # require 'webauthn'
    # # 

    # @current_account=ActsAsTenant.current_tenant 
    # EmailConfiguration.configure(@current_account)



    def authenticate_webauthn
      # "id": ""AdVZRNnFYkuE-z2ExPy7YNCjTEbBPiGqJHJ0DSMW8d_3H63vtT5dcjFWa_QUp5bNTimc5J3_SSXIeFVuUeAbxTo",
      # "5TR0TJqgdKRNuqsDhDQV6L7ccHct5B_xGUJ1HJWp0G4" =>  chalenge,
      admin = User.find_by(username: params[:user_name]) || User.find_by(email: params[:email])
      relying_party = WebAuthn::RelyingParty.new(
        origin: "https://#{request.headers['X-Subdomain']}.aitechs.co.ke",
        name: "#{request.headers['X-Subdomain']}.aitechs.co.ke",
        id: "#{request.headers['X-Subdomain']}.aitechs.co.ke"
      )
    
      # relying_party = WebAuthn::RelyingParty.new(
      #   # origin: "https://#{request.headers['X-Original-Host']}",
      #   origin: "http://localhost:5173",
      #   name: "#{request.headers['X-Original-Host']}",
      #   # id: request.headers['X-Original-Host']
      #   id: "localhost"
      # )
    
      if admin.present?
        options = relying_party.options_for_authentication(allow: admin.admin_web_authn_credentials.map { |c| c.webauthn_id })
        # admin_credentials = admin.credentials.map do |credential|
        #   {  id: Base64.urlsafe_encode64(credential.webauthn_id) }
        # end
    
        # options = WebAuthn::Credential.options_for_get(
        #   allow: admin_credentials,
        # )
        
       
        session[:authentication_challenge] = options.challenge
        Rails.logger.info "Challenge during authentication: #{session[:authentication_challenge]}"
    
        render json: options
        # render json:  @admin, serializer: AdminSerializer,   status: :accepted
      else
        render json: {error: 'username or email not found'}, status: :not_found
    
      end
    
    end
    
    
    


    def verify_webauthn
      begin
        # Find the admin user first
        admin = User.find_by(username: params[:user_name]) || User.find_by(email: params[:email])
    
        unless admin
          render json: { error: "User not found" }, status: :not_found
          return
        end
  
        # Check if the user has any registered passkeys
        unless admin.admin_web_authn_credentials.exists?
          render json: { 
            error: "No passkey found", 
            message: "Please register a passkey first before attempting to authenticate",
            needs_registration: true 
          }, status: :unprocessable_entity
          return
        end
  
        # Initialize the Relying Party
        # relying_party = WebAuthn::RelyingParty.new(
        #   origin: "http://localhost:5173",
        #   # name: "aitechs",
        #   name: "#{request.headers['X-Original-Host']}",
        #   id: "localhost"
        # )
        # 
        #
        relying_party = WebAuthn::RelyingParty.new(
          origin: "https://#{request.headers['X-Subdomain']}.aitechs.co.ke",
          name: "#{request.headers['X-Subdomain']}.aitechs.co.ke",
          id: "#{request.headers['X-Subdomain']}.aitechs.co.ke"
        )
  
        # Validate incoming credential
        public_key_credential = params[:credential]
        if public_key_credential.nil?
          render json: { error: "PublicKeyCredential is missing" }, status: :unprocessable_entity
          return
        end
  
        # Extract and validate challenge
        challenge = public_key_credential[:challenge]
        if challenge.blank?
          render json: { error: "Challenge is missing" }, status: :unprocessable_entity
          return
        end
  
        # Log the incoming credential ID for debugging
        # Rails.logger.info "Incoming credential ID: #{public_key_credential[:id]}"
        # Rails.logger.info "Admin credentials: #{admin.credentials.pluck(:webauthn_id)}"
  
        # First, try to find the credential directly
        stored_credential = admin.admin_web_authn_credentials.find_by(webauthn_id: public_key_credential[:id])
        
        unless stored_credential
          Rails.logger.error "No matching credential found for ID: #{public_key_credential[:id]}"
          render json: { 
            error: "Invalid credential", 
            message: "The provided passkey doesn't match any registered passkeys for this user. Please ensure you're using the correct passkey or register a new one.",
            needs_registration: admin.admin_web_authn_credentials.empty?
          }, status: :unauthorized
          return
        end
  
        Rails.logger.info "Found stored credential: #{stored_credential.inspect}"
  
        begin
          # Find the stored credential for the admin
          # stored_credential = admin.credentials.find_by(webauthn_id: params[:credential][:id])
      
      
          webauthn_credential, stored_credential = relying_party.verify_authentication(
            public_key_credential,
            challenge
          ) do |webauthn_credential|
            # Find the stored credential based on the external ID
            admin.admin_web_authn_credentials.find_by(webauthn_id: webauthn_credential.id)
          end
          Rails.logger.info "Stored credentials for #{admin.email}: #{stored_credential.inspect}"
      
          # webauthn_credential = WebAuthn::Credential.from_get(params[:credential])
      
      
          # # Verify the credential using the relying party
          # relying_party.verify_authentication(
          #   challenge,
          #   # params[:credential],
          #   webauthn_credential
          # )
      
          # Update admin's last activity and login time
          # admin.update_column(:inactive, false)
          # admin.update_column(:last_activity_active, Time.zone.now)
          # admin.update_column(:last_login_at, Time.now)
      
          # Generate a token and set it in cookies
          token = generate_token(user_id: admin.id)
          cookies.encrypted.signed[:jwt_user] = { value: token, httponly: true,
           secure: true, exp: 24.hours.from_now.to_i, sameSite: 'strict' }
      
          # Update the sign count for the stored credential
          stored_credential.update!(sign_count: webauthn_credential.sign_count)
      
          render json: { message: 'WebAuthn authentication successful' }, status: :ok
        rescue WebAuthn::Error => e
          Rails.logger.error "WebAuthn Error: #{e.message}"
          render json: { error: e.message }, status: :unprocessable_entity
        end
      rescue WebAuthn::Error => e
        Rails.logger.error "WebAuthn Error: #{e.message}"
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
    
    















def get_passkey_credentials


  if  current_user
    credentials = current_user.admin_web_authn_credentials
    render json: { credentials: current_user.admin_web_authn_credentials }, include: [:user], status: :ok
  else
     render json: { error: "Not authorized" }, status: :unauthorized
  end


end







     def update_admin
       
    @admin = current_user

    if !params[:email].match?(/\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/)
        render json: { error: "Invalid email" }, status: :unprocessable_entity
       return
    end

    
    filtered_params = user_params.except(:password, :password_confirmation) if user_params[:password].blank?
   
    if @admin.update(filtered_params || user_params)
      render json: {
        id: @admin.id,
        user_name: @admin.username,
        email: @admin.email,
        phone_number: @admin.phone_number
      }
    else
      render json: @admin.errors, status: :unprocessable_entity 
    end
  end





  def delete_webauthn
    @credential = current_user.admin_web_authn_credentials.find_by(id: params[:id])
    if @credential
      @credential.destroy()
      # WebAuthn.signal_unknown_credential(@credential.id)
      render json: { message: 'Credential deleted' }, status: :ok
    else
      render json: { error: 'Credential not found' }, status: :not_found
    end
  end



  def register_webauthn
    # First verify if the user is authorized to create a passkey
    # unless current_user&.role == 'super_administrator' || current_user&.role == 'system_administrator'
    #   render json: { error: 'Unauthorized: Only admins can register passkeys' }, status: :unauthorized
    #   return
    # end

    @the_admin = User.find_by(username: params[:username]) || User.find_by(email: params[:email])
    if @the_admin.nil?
      render json: { error: 'Admin not found' }, status: :not_found
      return
    end

    # Verify the user belongs to the current tenant
    unless @the_admin.account == ActsAsTenant.current_tenant
      render json: { error: 'Unauthorized: User does not belong to this tenant' }, status: :unauthorized
      return
    end

    # Check if user already has a passkey registered
    # if @the_admin.admin_web_authn_credentials.exists?
    #   render json: { error: 'A passkey is already registered for this user' }, status: :unprocessable_entity
    #   return
    # end

    # validate_admin_passkey_user_name

    if @the_admin&.errors&.empty?
      if @the_admin.save
        if @the_admin.webauthn_id.nil?
          @the_admin.update!(
            webauthn_id: WebAuthn.generate_user_id[0..32], 
            # date_registered: Time.now.strftime('%Y-%m-%d %I:%M:%S %p')
          )
        end

        # relying_party = WebAuthn::RelyingParty.new(
        #   origin: "http://#{request.headers['X-Subdomain']}",
        #   name: "#{request.headers['X-Subdomain']}",
        #   id: 'localhost'
        # )

        relying_party = WebAuthn::RelyingParty.new(
          origin: "https://#{request.headers['X-Subdomain']}.aitechs.co.ke",
          name: "#{request.headers['X-Subdomain']}.aitechs.co.ke",
          id: "#{request.headers['X-Subdomain']}.aitechs.co.ke"
        )



        options = relying_party.options_for_registration(
         
        user: { id: Base64.urlsafe_encode64(@the_admin.webauthn_id),
         name: @the_admin.username || @the_admin.email,
         display_name: @the_admin.email },

        authenticator_selection: {
          # Require resident key to ensure the credential is stored on the device
          require_resident_key: true,
          # User verification required for extra security
          user_verification_requirement: 'required',
          # Prevent silent authentications
          # authenticator_attachment: 'platform'
        },
        attestation: 'direct'
      )

        # Store challenge in session with expiration
        session[:webauthn_registration] = {
          challenge: options.challenge,
          expires_at: 5.minutes.from_now
        }

        Rails.logger.info "Challenge during registration: #{session[:webauthn_registration][:challenge]}"
        render json: options, status: :ok
      else  
        render json: @the_admin.errors, status: :unprocessable_entity
      end
    else  
      render json: @the_admin&.errors, status: :unprocessable_entity
    end
  end

  
  
  
  
  
  
  def create_webauthn
    begin
  
      # relying_party = WebAuthn::RelyingParty.new(
      #   # origin: "https://#{request.headers['X-Original-Host']}",
      #   origin: "http://localhost:5173",
      #   # name: "fiber8",
      #   name: "#{request.headers['X-Original-Host']}",
      #   # id: request.headers['X-Original-Host']
      #   id: "localhost"
      # )
      # 
      #
      relying_party = WebAuthn::RelyingParty.new(
        origin: "https://#{request.headers['X-Subdomain']}.aitechs.co.ke",
        name: "#{request.headers['X-Subdomain']}.aitechs.co.ke",
        id: "#{request.headers['X-Subdomain']}.aitechs.co.ke"
      )
  
      challenge = params[:credential][:challenge]
  
  
      webauthn_credential = relying_party.verify_registration(
        params[:credential],
        challenge
        
        )
      admin = User.find_by(username: params[:username]) || User.find_by(email: params[:email])
      # Check if the session data is present
  
      if challenge.blank?
        Rails.logger.warn "Challenge is missing from the request"
        render json: { error: "Challenge is missing" }, status: :unprocessable_entity
        return
      end 
  
      # if session[:webauthn_registration].blank?
      #   Rails.logger.warn "Session data for webauthn_registration is missing or nil"
      #   render json: { error: "Challenge is missing" }, status: :unprocessable_entity
      #   return
      # end 
  
      # Verify the credential
      # webauthn_credential.verify(session[:webauthn_registration])
      # webauthn_credential.verify(challenge)
      admin.admin_web_authn_credentials.create!(
        webauthn_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count
      )
  
      # session[:webauthn_registration] = nil
      render json: { message: 'WebAuthn registration successful' }, status: :ok
    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn Error: #{e.message}"
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
  
  






    
    def destroy
        # session.delete :user_id
        
        cookies.delete(:jwt_user)
        head :no_content
    end

def currently_logged_in_user
    if  current_user
        render json: current_user, status: :accepted
    else
        render json: { error: "Not authorized" }, status: :unauthorized
    end
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
        if @user.nil?
          render json: { error: 'User Not Found' }, status: :not_found and return
        end

if @user.locked_account == true && @user&.locked_at > 5.minutes.ago
  render json: { error: 'Account locked' }, status: :locked # 423 Locked
      

      else

       



        if @user&.authenticate(params[:password])
          # set_current_tenant(@user.account)
          # session[:user_id] = @user.id
          # reset_login_attempts 
          token = generate_token(user_id: @user.id)
    
          cookies.encrypted.signed[:jwt_user] = { value: token, httponly: true, secure: true,
         sameSite: 'strict'}



     

     



render json:@user,   status: :accepted

             
        


      else
        render json: { error: 'Invalid email or password' }, status: :unauthorized
      end
      end
    

    end


    private



    def reset_login_attempts
      key = "failed_logins:#{request.remote_ip}"
      Rails.cache.delete(key)  # ✅ Reset count on successful login
    end



    
    def generate_token(payload)
        JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
      end

    def validate_admin_update
      
      
         
        if !params[:email].match?(/\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/)
            @admin.errors.add(:email, "is not a valid email")
        end
      
      end







    def user_params
        params.permit(:email, :password, :password_confirmation, :username, :phone_number)
      end
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


