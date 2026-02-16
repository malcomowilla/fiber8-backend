class SystemAdminsController < ApplicationController
  # before_action :set_system_admin, only: %i[ show edit update destroy ]

  
before_action :set_system_admin_email_settings

# set_current_tenant_through_filter

# before_action :set_tenant

  def index
    @system_admins = SystemAdmin.all
    render json: @system_admins
  end



  def current_plan
      @current_plan = ActsAsTenant.current_tenant&.pp_poe_plan
      render json: {current_plan: @current_plan&.name}
  end



  def current_hotspot_plan
    
    @current_hotspot_plan = ActsAsTenant.current_tenant&.hotspot_plan
    render json: {current_hotspot_plan: @current_hotspot_plan&.name}
end



  # def set_tenant
  #   host = request.headers['X-Subdomain']
  #   @account = Account.find_by(subdomain: host)
  #    ActsAsTenant.current_tenant = @account
  #   EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  #   # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
  #   Rails.logger.info "set_current_tenant #{ActsAsTenant.current_tenant.inspect}"
  #   # set_current_tenant(@account)
  # rescue ActiveRecord::RecordNotFound
  #   render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  # end



  
  def authenticate_webauthn_login_system_admin
    # "id": ""AdVZRNnFYkuE-z2ExPy7YNCjTEbBPiGqJHJ0DSMW8d_3H63vtT5dcjFWa_QUp5bNTimc5J3_SSXIeFVuUeAbxTo",
    # "5TR0TJqgdKRNuqsDhDQV6L7ccHct5B_xGUJ1HJWp0G4" =>  chalenge,
    admin = SystemAdmin.find_by(phone_number: params[:phone_number]) || SystemAdmin.find_by(email: params[:email])
  
  
    relying_party = WebAuthn::RelyingParty.new(
     
      #  # origin: "https://#{request.headers['X-Original-Host']}",
      # # origin: "https://#{request.headers['X-Subdomain-Aitechs']}",
      # origin: "https://#{request.headers['X-Subdomain']}",
      # name: "#{request.headers['X-Subdomain']}",
      # # id: request.headers['X-Original-Host']
      # id: "#{request.headers['X-Subdomain']}"
      # origin: "https://#{request.headers['X-Subdomain']}.aitechs.co.ke",
      # name: "#{request.headers['X-Subdomain']}.aitechs.co.ke",
      # id: "#{request.headers['X-Subdomain']}.aitechs.co.ke" 
       origin: "https://aitechs.co.ke",
      name: "aitechs.co.ke",
      id: "aitechs.co.ke" 




    )
  
    if admin.present?
      options = relying_party.options_for_authentication(allow: admin.system_admin_web_authn_credentials.map { |c| c.webauthn_id })
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
 
  
  def verify_webauthn_login_system_admin
    begin
      # Find the admin user first
      admin = SystemAdmin.find_by(phone_number: params[:phone_number]) || SystemAdmin.find_by(email: params[:email])
  
      unless admin
        render json: { error: "User not found" }, status: :not_found
        return
      end

      # Check if the user has any registered passkeys
      unless admin.system_admin_web_authn_credentials.exists?
        render json: { 
          error: "No passkey found", 
          message: "Please register a passkey first before attempting to authenticate",
          needs_registration: true 
        }, status: :unprocessable_entity
        return
      end

      # Initialize the Relying Party
      relying_party = WebAuthn::RelyingParty.new(
         # origin: "https://#{request.headers['X-Subdomain-Aitechs']}",
      # origin: "http://localhost:5173",
      # # name: "#{request.headers['x-subdomain']}",
      #  name: 'aitechs', 
      # # id: request.headers['X-Original-Host']
      # # id: "#{request.headers['x-subdomain']}"
      #  id: 'localhost'
       # origin: "https://#{request.headers['X-Original-Host']}",
      # origin: "https://#{request.headers['X-Subdomain-Aitechs']}",
      # origin: "https://#{request.headers['X-Subdomain']}",
      # name: "#{request.headers['X-Subdomain']}",
      # # id: request.headers['X-Original-Host']
      # id: "#{request.headers['X-Subdomain']}"  
      
      # origin: "https://#{request.headers['X-Subdomain']}.aitechs.co.ke",
      # name: "#{request.headers['X-Subdomain']}.aitechs.co.ke",
      # id: "#{request.headers['X-Subdomain']}.aitechs.co.ke" 
       origin: "https://aitechs.co.ke",
      name: "aitechs.co.ke",
      id: "aitechs.co.ke" 

      
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
    
      # First, try to find the credential directly
      stored_credential = admin.system_admin_web_authn_credentials.find_by(webauthn_id: public_key_credential[:id])
      
      unless stored_credential
        Rails.logger.error "No matching credential found for ID: #{public_key_credential[:id]}"
        render json: { 
          error: "Invalid credential", 
          message: "The provided passkey doesn't match any registered passkeys for this user. Please ensure you're using the correct passkey or register a new one.",
          needs_registration: admin.system_admin_web_authn_credentials.empty?
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
          admin.system_admin_web_authn_credentials.find_by(webauthn_id: webauthn_credential.id)
        end
    
        # webauthn_credential = WebAuthn::Credential.from_get(params[:credential])
    
    
        # # Verify the credential using the relying party
        # relying_party.verify_authentication(
        #   challenge,
        #   # params[:credential],
        #   webauthn_credential
        # )
    
      
        token = generate_token(system_admin_id: admin.id)
        cookies.encrypted.signed[:jwt_system_admin] = { value: token, 
        httponly: true, secure: true,
       sameSite: 'strict'}


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





  
  

def register_webauthn_system_admin

  @the_admin = SystemAdmin.find_by(phone_number: params[:phone_number]) || SystemAdmin.find_by(email: params[:email])
  if @the_admin.nil?
    render json: { error: 'Admin not found' }, status: :not_found
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

      relying_party = WebAuthn::RelyingParty.new(
      
      # origin: "https://#{request.headers['X-Subdomain']}.aitechs.co.ke",
      # name: "#{request.headers['X-Subdomain']}.aitechs.co.ke",
      # id: "#{request.headers['X-Subdomain']}.aitechs.co.ke" 


       origin: "https://aitechs.co.ke",
      name: "aitechs.co.ke",
      id: "aitechs.co.ke" 




         # origin: "https://#{request.headers['X-Original-Host']}",
      # origin: "https://#{request.headers['X-Subdomain-Aitechs']}",
      # origin: "https://#{request.headers['X-Subdomain']}",
      # name: "#{request.headers['X-Subdomain']}",
      # # id: request.headers['X-Original-Host']
      # id: "#{request.headers['X-Subdomain']}"
      )



      options = relying_party.options_for_registration(
       
      user: { id: Base64.urlsafe_encode64(@the_admin.webauthn_id),
       name: @the_admin.email,
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





def create_webauthn_system_admin
  begin
  
    relying_party = WebAuthn::RelyingParty.new(
      # origin: "https://#{request.headers['X-Original-Host']}",
      # origin: "https://#{request.headers['X-Subdomain-Aitechs']}",
      #   origin: "https://#{request.headers['X-Subdomain']}",
      # name: "#{request.headers['X-Subdomain']}",
      # # id: request.headers['X-Original-Host']
      # id: "#{request.headers['X-Subdomain']}"

      # origin: "https://#{request.headers['X-Subdomain']}.aitechs.co.ke",
      # name: "#{request.headers['X-Subdomain']}.aitechs.co.ke",
      # id: "#{request.headers['X-Subdomain']}.aitechs.co.ke" 
       origin: "https://aitechs.co.ke",
      name: "aitechs.co.ke",
      id: "aitechs.co.ke" 

    )


    challenge = params[:credential][:challenge]


    webauthn_credential = relying_party.verify_registration(
      params[:credential],
      challenge
      
      )
    admin = SystemAdmin.find_by(phone_number: params[:phone_number]) || User.find_by(email: params[:email])
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
    admin.system_admin_web_authn_credentials.create!(
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





def get_passkey_credentials_system_admin


  if  current_system_admin
    # credentials = current_user.admin_web_authn_credentials
    render json: { credentials: current_system_admin.system_admin_web_authn_credentials}, include: [:system_admin], status: :ok
  else
     render json: { error: "No system admin found for fetching passkey credentials" }, status: :unauthorized
  end


end

  def set_system_admin_email_settings
# @current_account = ActsAsTenant.current_tenant
#     EmailSystemAdmin.configure(@current_account, current_system_admin)
  @current_account = ActsAsTenant.current_tenant 
  EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])

  end




  def invite_company_super_admins
    # validate_invite_super_admin
  
    # Initialize @my_admin with the provided parameters
    @my_admin = User.find_or_create_by(
      username: params[:username],
      email: params[:email],
      phone_number: params[:phone_number]
    )
  

   account_id = Account.find_or_create_by(subdomain: params[:company_name])



    @my_admin.password = generate_secure_password(16)
    # @my_admin.password_confirmation = generate_secure_password(16)

    # @my_admin.update!(account_id: account_id.id)
  ActsAsTenant.with_tenant(account_id) do
  @my_admin = User.create!(
    username: params[:username],
    email: params[:email],
    phone_number: params[:phone_number],
    password: params[:password],
    password_confirmation: params[:password]
  )
end
@my_admin.update!(password: params[:password],  password_confirmation: params[:password])



    @my_admin.role = 'super_administrator'
    #  @my_admin.account = ActsAsTenant.current_tenant
    @my_admin.update(date_registered: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'))


    # if @my_admin.errors.empty?
      if @my_admin.save
        # AdminOnboardingMailer.admin_onboarding(@my_admin, 
       
        #   ).deliver_now

        AdminOnboardingMailer.admin_onboarding(@my_admin).deliver_now
        BlockedUserMailer.notify_block(@my_admin).deliver_now
        send_password(@my_admin.phone_number, @my_admin.password, @my_admin.email)
        render json: @my_admin, status: :created
      else
        render json: { errors: @my_admin.errors }, status: :unprocessable_entity
      end
    # else
    #   render json: { errors: @my_admin.errors }, status: :unprocessable_entity
    # end
  end




  def update_client
    admin = User.find_by(id: params[:id])
    
    unless admin
      return render json: { error: "Admin not found!" }, status: :unprocessable_entity
    end
  
    admin.update(
      username: params[:username],
      email: params[:email],
      phone_number: params[:phone_number],
      password: params[:password],
      password_confirmation: params[:password]
      
    )

render json: admin, status: :ok

  end
  



def check_sms_already_verified
  admin = SystemAdmin.find_by(system_admin_phone_number: params[:phone_number] ) || SystemAdmin.find_by(system_admin_phone_number: params[:phone_number2])
  if admin
    render json: { sms_verified: admin.system_admin_phone_number_verified }, status: :ok
  else
    render json: { error: 'SystemAdmin not found.' }, status: :not_found
  end
end



def check_email_already_verified
  admin = SystemAdmin.find_by(email: params[:email]) || SystemAdmin.find_by(system_admin_phone_number: params[:phone_number] ) || SystemAdmin.find_by(system_admin_phone_number: params[:phone_number2]
  )
  if admin
    render json: { email_verified: admin.email_verified }, status: :ok
  else
    render json: { error: 'SystemAdmin not found.' }, status: :not_found
  end


end



  def current_system_admin_controller_of_networks

    if current_system_admin
      render json: current_system_admin, status: :ok

    else
render json: { error: 'System Admin not found' }, status: :unauthorized

    end


  end



  def get_system_admin_settings
    sys_settings =  SystemAdminSetting.all
    render json: sys_settings
    
      end




  def create_system_admin_settings
    if current_system_admin
      sys_setings =  current_system_admin.system_admin_setting || current_system_admin.build_system_admin_setting
      

      sys_setings.update(login_with_passkey: params[:login_with_passkey], 
      use_email_authentication: params[:use_email_authentication],
      use_sms_authentication: params[:use_sms_authentication]
      )
      render json: { message: 'Login with passkey updated successfully' }, status: :ok
    else

      render json: { error: 'not authorized' }, status: :unauthorized
      return
    end


  end






  def login
    @user = SystemAdmin.find_by(
      system_admin_phone_number: params[:phone_number]
    ) || SystemAdmin.find_by(
      email: params[:email])

    if @user&.authenticate(params[:password])
      if @user.system_admin_setting&.use_sms_authentication 
        if @user.system_admin_phone_number_verified

          token = generate_token(system_admin_id:  @user.id)
          cookies.encrypted.signed[:jwt_system_admin] = { value: token, 
          httponly: true, secure: true,
         sameSite: 'strict'}
         render json:@user,   status: :accepted

        else
          @user.generate_otp
          send_otp(@user.system_admin_phone_number, @user.otp, @user.user_name)
          render json: { message: 'OTP sent successfully' }, status: :ok
        end
      elsif @user.system_admin_setting&.use_email_authentication
        
        if @user.email_verified == true 

          token = generate_token(system_admin_id:  @user.id)
          cookies.encrypted.signed[:jwt_system_admin] = { value: token, 
          httponly: true, secure: true,
         sameSite: 'strict'}
         render json:@user,   status: :accepted

        else
          @user.generate_otp
          AdminOtpMailer.admin_otp(@user).deliver_now
          # send_otp(@user.system_admin_phone_number, @user.otp, @user.user_name)
          render json: { message: 'OTP sent successfully' }, status: :ok
        end
      else

        if  @user.system_admin_setting&.login_with_passkey  == true || @user.system_admin_setting&.login_with_passkey == 'true'

          render json:@user,   status: :accepted
        else

          token = generate_token(system_admin_id:  @user.id)
          cookies.encrypted.signed[:jwt_system_admin] = { value: token, 
          httponly: true, secure: true,
         sameSite: 'strict'}
       render json:@user,   status: :accepted
        end
      end

    else
      render json: { error: 'Invalid phone number or password' }, status: :unauthorized
    end
  end















  def verify_otp
    system_admin = SystemAdmin.find_by(email: params[:email]) || SystemAdmin.find_by(system_admin_phone_number: params[:phone_number]) || SystemAdmin.find_by(phone_number: params[:phone_number2])

    if  system_admin&.verify_otp(params[:otp])
      system_admin.update(system_admin_phone_number_verified: true, otp: nil)
      system_admin.system_admin_setting.update(use_email_authentication: false, use_sms_authentication: false)

      token = generate_token(system_admin_id:  system_admin.id)
      cookies.encrypted.signed[:jwt_system_admin] = { value: token, httponly: true, secure: true , exp: 24.hours.from_now.to_i , sameSite: 'strict'}
      render json: { message: 'Login successful' }, status: :ok

      
    else
      render json: { message: 'Invalid OTP' }, status: :unauthorized
    end

  end



  def verify_otp_email
    system_admin = SystemAdmin.find_by(email: params[:email]) ||
     SystemAdmin.find_by(system_admin_phone_number_verified: params[:phone_number]) || 
     SystemAdmin.find_by(phone_number: params[:phone_number2])

    if  system_admin&.verify_otp(params[:otp]) 
      system_admin.update(email_verified: true, otp: nil)
      system_admin.system_admin_setting.update(use_email_authentication: false)
      token = generate_token(system_admin_id:  system_admin.id)
      cookies.encrypted.signed[:jwt_system_admin] = { value: token, httponly: true, secure: true , exp: 24.hours.from_now.to_i , sameSite: 'strict'}
      render json: { message: 'Login successful' }, status: :ok

      
    else
      render json: { message: 'Invalid OTP' }, status: :unauthorized
    end

  end





  # POST /system_admins or /system_admins.json
  def create
    @system_admin = SystemAdmin.new(system_admin_params)

    respond_to do |format|
      if @system_admin.save
        format.html { redirect_to system_admin_url(@system_admin), notice: "System admin was successfully created." }
        format.json { render :show, status: :created, location: @system_admin }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @system_admin.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /system_admins/1 or /system_admins/1.json
  def update
    respond_to do |format|
      if @system_admin.update(system_admin_params)
        format.html { redirect_to system_admin_url(@system_admin), notice: "System admin was successfully updated." }
        format.json { render :show, status: :ok, location: @system_admin }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @system_admin.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /system_admins/1 or /system_admins/1.json
  def destroy
    @system_admin.destroy!

    respond_to do |format|
      format.html { redirect_to system_admins_url, notice: "System admin was successfully destroyed." }
      format.json { head :no_content }
    end
  end


  def logout
    
    cookies.delete(:jwt_system_admin)
    head :no_content
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_system_admin
      @system_admin = SystemAdmin.find(params[:id])
    end



    def generate_token(payload)
      JWT.encode(payload, ENV['JWT_SECRET_KEY'], 'HS256')
    end

    # Only allow a list of trusted parameters through.
    def system_admin_params
      params.require(:system_admin).permit(:user_name, :password_digest, :email, :verification_token, :email_verified, :role, :fcm_token, :webauthn_id, :webauthn_authenticator_attachment, :login_with_passkey)
    end


    def send_otp(phone_number, otp, name)


# SMS_LEOPARD_API_KEY= c3I6A1BuUvESuTkdSa2l
# SMS_LEOPARD_API_SECRET=aSYTHMEmRF3XQUUSPANeYGEeGlZYTYGYFj4TXWqV
      api_key = 'c3I6A1BuUvESuTkdSa2l'
      api_secret = 'aSYTHMEmRF3XQUUSPANeYGEeGlZYTYGYFj4TXWqV'
      original_message =   "Hello, #{name} use this one time
       password #{otp} to continue"
      sender_id = "SMS_TEST" # Ensure this is a valid sender ID
  
      uri = URI("https://api.smsleopard.com/v1/sms/send")
      params = {
        username: api_key,
        password: api_secret,
        message: original_message,
        destination: phone_number,
        source: sender_id
      }
      uri.query = URI.encode_www_form(params)
  
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess)
        sms_data = JSON.parse(response.body)
    
        if sms_data['success']
          sms_recipient = sms_data['recipients'][0]['number']
          sms_status = sms_data['recipients'][0]['status']
          
          puts "Recipient: #{sms_recipient}, Status: #{sms_status}"
    
          # Save the original message and response details in your database
          SystemAdminSm.create!(
            user: sms_recipient,
            message: original_message,
            status: sms_status,
            date:Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
            system_user: 'system'
          )
          
          # Return a JSON response or whatever is appropriate for your application
          # render json: { success: true, message: "Message sent successfully", recipient: sms_recipient, status: sms_status }
        else
          render json: { error: "Failed to send message: #{sms_data['message']}" }
        end
      else
        puts "Failed to send message: #{response.body}"
        # render json: { error: "Failed to send message: #{response.body}" }
      end
    end



    def send_password(phone_number, password, email)
      api_key = 'c3I6A1BuUvESuTkdSa2l'
      api_secret = 'aSYTHMEmRF3XQUUSPANeYGEeGlZYTYGYFj4TXWqV'

      
      original_message = "Hello use this credentials to login to your account password:#{password} email:#{email}"
      sender_id = "SMS_TEST" # Ensure this is a valid sender ID
  
      uri = URI("https://api.smsleopard.com/v1/sms/send")
      params = {
        username: api_key,
        password: api_secret,
        message: original_message,
        destination: phone_number,
        source: sender_id
      }
      uri.query = URI.encode_www_form(params)
  
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess)
        sms_data = JSON.parse(response.body)
    
        if sms_data['success']
          sms_recipient = sms_data['recipients'][0]['number']
          sms_status = sms_data['recipients'][0]['status']
          
          puts "Recipient: #{sms_recipient}, Status: #{sms_status}"
    
          # Save the original message and response details in your database
          SystemAdminSm.create!(
            user: sms_recipient,
            message: original_message,
            status: sms_status,
            date:Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
            system_user: 'system'
          )
          
          # Return a JSON response or whatever is appropriate for your application
          # render json: { success: true, message: "Message sent successfully", recipient: sms_recipient, status: sms_status }
        else
          render json: { error: "Failed to send message: #{sms_data['message']}" }
        end
      else
        puts "Failed to send message: #{response.body}"
        # render json: { error: "Failed to send message: #{response.body}" }
      end
    end


    def generate_secure_password(length = 12)
      raise ArgumentError, 'Length must be at least 8' if length < 8
    
      # Define the character sets
      lowercase = ('a'..'z').to_a
      uppercase = ('A'..'Z').to_a
      digits = ('0'..'9').to_a
      symbols = %w[! @ # $ % ^ & * ( ) - _ = + { } [ ] | : ; " ' < > , . ? /]
    
      # Combine all character sets
      all_characters = lowercase + uppercase + digits + symbols
    
      # Ensure the password contains at least one character from each set
      password = []
      password << lowercase.sample
      password << uppercase.sample
      password << digits.sample
      password << symbols.sample
    
      # Fill the rest of the password length with random characters from all sets
      (length - 4).times { password << all_characters.sample }
    
      # Shuffle the password to ensure randomness
      password.shuffle!
    
      # Join the array into a string
      password.join
    end




  




end
