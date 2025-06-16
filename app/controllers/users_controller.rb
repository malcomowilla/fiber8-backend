  class UsersController < ApplicationController
    load_and_authorize_resource except: [:authenticate_webauthn, :verify_webauthn, :profile]

    rescue_from ActiveRecord::RecordInvalid, with: :creation_error 

    # def set_current_tenant
    #   # Extract subdomain and domain from request
    #   subdomain = request.subdomain
    
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
    


    def unblock_email
      email = params[:email]
      cache_key = "rack::attack:logins/email:#{email.downcase.strip}"
  
      if Rails.cache.exist?(cache_key)
        Rails.cache.delete(cache_key)
        render json: { message: "Email #{email} unblocked successfully." }, status: :ok
      else
        render json: { error: "Email #{email} not found or not blocked." }, status: :not_found
      end
    end
  
    def unblock_ip
      ip = params[:ip]
      cache_key = "rack::attack:logins/ip:#{ip}"
  
      if Rails.cache.exist?(cache_key)
        Rails.cache.delete(cache_key)
        render json: { message: "IP #{ip} unblocked successfully." }, status: :ok
      else
        render json: { error: "IP #{ip} not found or not blocked." }, status: :not_found
      end
    end




    def authenticate_webauthn
      # "id": ""AdVZRNnFYkuE-z2ExPy7YNCjTEbBPiGqJHJ0DSMW8d_3H63vtT5dcjFWa_QUp5bNTimc5J3_SSXIeFVuUeAbxTo",
      # "5TR0TJqgdKRNuqsDhDQV6L7ccHct5B_xGUJ1HJWp0G4" =>  chalenge,
      admin = User.find_by(username: params[:username]) || User.find_by(email: params[:email])
    
    
      relying_party = WebAuthn::RelyingParty.new(
        # origin: "https://#{request.headers['X-Original-Host']}",
        origin: "http://localhost:5173",
        name: "#{request.headers['X-Original-Host']}",
        # id: request.headers['X-Original-Host']
        id: "localhost"
      )
    
      if admin.present?
        options = relying_party.options_for_authentication(allow: admin.credentials.map { |c| c.webauthn_id })
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
        admin = User.find_by(username: params[:username]) || User.find_by(email: params[:email])
    
        unless admin
          render json: { error: "User not found" }, status: :not_found
          return
        end
  
        # Check if the user has any registered passkeys
        unless admin.credentials.exists?
          render json: { 
            error: "No passkey found", 
            message: "Please register a passkey first before attempting to authenticate",
            needs_registration: true 
          }, status: :unprocessable_entity
          return
        end
  
        # Initialize the Relying Party
        relying_party = WebAuthn::RelyingParty.new(
          origin: "http://localhost:5173",
          # name: "aitechs",
          name: "#{request.headers['X-Original-Host']}",
          id: "localhost"
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
        Rails.logger.info "Incoming credential ID: #{public_key_credential[:id]}"
        Rails.logger.info "Admin credentials: #{admin.credentials.pluck(:webauthn_id)}"
  
        # First, try to find the credential directly
        stored_credential = admin.credentials.find_by(webauthn_id: public_key_credential[:id])
        
        unless stored_credential
          Rails.logger.error "No matching credential found for ID: #{public_key_credential[:id]}"
          render json: { 
            error: "Invalid credential", 
            message: "The provided passkey doesn't match any registered passkeys for this user. Please ensure you're using the correct passkey or register a new one.",
            needs_registration: admin.credentials.empty?
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
            admin.credentials.find_by(webauthn_id: webauthn_credential.id)
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
          admin.update_column(:inactive, false)
          admin.update_column(:last_activity_active, Time.zone.now)
          admin.update_column(:last_login_at, Time.now)
      
          # Generate a token and set it in cookies
          token = generate_token(admin_id: admin.id)
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
    
    

