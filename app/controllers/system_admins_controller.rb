class SystemAdminsController < ApplicationController
  # before_action :set_system_admin, only: %i[ show edit update destroy ]

  # GET /system_admins or /system_admins.json
  def index
    @system_admins = SystemAdmin.all
    render json: @system_admins
  end





  def invite_company_super_admins
    # validate_invite_super_admin
  
    # Initialize @my_admin with the provided parameters
    @my_admin = User.find_or_create_by(
      username: params[:username],
      email: params[:email],
      phone_number: params[:phone_number]
    )
  


    @my_admin.password = generate_secure_password(16)
    @my_admin.password_confirmation = generate_secure_password(16)
    @my_admin.role = 'super_administrator'
  
  

    if @my_admin.errors.empty?
      if @my_admin.save
        # AdminOnboardingMailer.admin_onboarding(@my_admin, 
       
        #   ).deliver_now


        send_password(@my_admin.phone_number, @my_admin.username, @my_admin.password, @my_admin.email)
        render json: @my_admin, status: :created
      else
        render json: { errors: @my_admin.errors }, status: :unprocessable_entity
      end
    else
      render json: { errors: @my_admin.errors }, status: :unprocessable_entity
    end
  end









def check_sms_already_verified
  admin = SystemAdmin.find_by(system_admin_phone_number: params[:phone_number] ) || SystemAdmin.find_by(system_admin_phone_number: params[:phone_number2])
  if admin
    render json: { sms_verified: admin.system_admin_phone_number_verified }, status: :ok
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



  def login
    @user = SystemAdmin.find_by(
      system_admin_phone_number: params[:phone_number]
    )

    if @user&.authenticate(params[:password])
      
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


    else
      render json: { error: 'Invalid phone number or password' }, status: :unauthorized
    end


  
  end





  def verify_otp
    system_admin = SystemAdmin.find_by(email: params[:email]) || SystemAdmin.find_by(phone_number: params[:phone_number]) || SystemAdmin.find_by(phone_number: params[:phone_number2])

    if  system_admin&.verify_otp(params[:otp])
      system_admin.update(system_admin_phone_number_verified: true)
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
      JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
    end

    # Only allow a list of trusted parameters through.
    def system_admin_params
      params.require(:system_admin).permit(:user_name, :password_digest, :email, :verification_token, :email_verified, :role, :fcm_token, :webauthn_id, :webauthn_authenticator_attachment, :login_with_passkey)
    end


    def send_otp(phone_number, otp, name)
      api_key = ENV['SMS_LEOPARD_API_KEY']
      api_secret = ENV['SMS_LEOPARD_API_SECRET']
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



    def send_password(phone_number, username, password, email)
      api_key = ENV['SMS_LEOPARD_API_KEY']
      api_secret = ENV['SMS_LEOPARD_API_SECRET']
      original_message =   "Hello, #{username} use this credentials to login to your account password:#{password} email:#{email}"
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
