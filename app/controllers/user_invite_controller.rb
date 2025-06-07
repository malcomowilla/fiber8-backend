
class UserInviteController < ApplicationController

before_action :update_last_activity


  set_current_tenant_through_filter
before_action :set_tenant



  def set_tenant

  host = request.headers['X-Subdomain']
  @account = Account.find_by(subdomain: host)


  set_current_tenant(@account)
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Invalid tenant' }, status: :not_found

  
end




     def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end





  def invite_users

    if User.exists?(username: params[:username])
      render json: { error: "username already exists" }, status: :unprocessable_entity
      return
      
    end
    

    if User.exists?(email: params[:email])
      render json: { error: "email already exists" }, status: :unprocessable_entity
      return
      
    end
    
    if params[:email].blank?
      render json: { error: "email is required" }, status: :unprocessable_entity
      return
    end



    if params[:role].blank?
      render json: { error: "Role is required" }, status: :unprocessable_entity
      return
    end

    @my_admin = User.new(admin_params)

    # email_valid = Truemail.validate(params[:email])
     @my_admin.password = generate_secure_password(16)
    
  
    # unless email_valid.result.valid?
    #   render json: { error: "Invalid email format or domain" }, status: :unprocessable_entity
    #   return
    # end
    # 
    #
      # t.string "can_manage_calendar"
# t.string "can_read_calendar"
# 
    if @my_admin.save
      @my_admin.update(
        role: params[:role],
        date_registered: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
        can_manage_subscriber: params[:can_manage_subscriber],
        username: params[:username],
        can_read_read_subscriber: params[:can_read_read_subscriber],
        can_manage_ticket_settings: params[:can_manage_ticket_settings],
        can_read_ticket_settings: params[:can_read_ticket_settings],
        can_read_ppoe_package: params[:can_read_ppoe_package],
        can_manage_ppoe_package: params[:can_manage_ppoe_package],
        can_manage_company_setting: params[:can_manage_company_setting],
        can_read_company_setting: params[:can_read_company_setting],
        can_manage_email_setting: params[:can_manage_email_setting],
        can_read_email_setting: params[:can_read_email_setting],
        can_manage_hotspot_packages: params[:can_manage_hotspot_packages],
        can_read_hotspot_packages: params[:can_read_hotspot_packages],
        can_manage_ip_pool: params[:can_manage_ip_pool],
        can_read_ip_pool: params[:can_read_ip_pool],
        can_manage_nas_routers: params[:can_manage_nas_routers],
        can_read_nas_routers: params[:can_read_nas_routers],
        can_manage_router_setting: params[:can_manage_router_setting],
        can_manage_sms:  params[:can_manage_sms],
        can_read_sms:  params[:can_read_sms],
        can_manage_sms_settings: params[:can_manage_sms_settings],
        can_read_sms_settings: params[:can_read_sms_settings],
        can_manage_subscriber_setting: params[:can_manage_subscriber_setting],
        can_read_subscriber_setting: params[:can_read_subscriber_setting],
        can_manage_subscription: params[:can_manage_subscription],
         can_read_subscription: params[:can_read_subscription],
         can_manage_support_tickets: params[:can_manage_support_tickets],
        can_read_support_tickets: params[:can_read_support_tickets],
        can_manage_users: params[:can_manage_users],
         can_read_users: params[:can_read_users],
         can_manage_zones: params[:can_manage_zones],
         can_read_zones: params[:can_read_zones],
can_manage_mpesa_settings: params[:can_manage_mpesa_settings],
can_read_mpesa_settings: params[:can_read_mpesa_settings],
  can_manage_user_setting: params[:can_manage_user_setting],
  can_read_user_setting: params[:can_read_user_setting],
  can_read_router_setting: params[:can_read_router_setting],
  can_manage_free_radius: params[:can_manage_free_radius],
can_read_free_radius: params[:can_read_free_radius],
can_reboot_router: params[:can_reboot_router],
can_manage_user_group: params[:can_read_user_group],
can_read_user_group: params[:can_read_user_group],
can_manage_hotspot_template: params[:can_manage_hotspot_template],
can_read_hotspot_template: params[:can_read_hotspot_template],
can_read_hotspot_voucher: params[:can_read_hotspot_voucher],
can_manage_hotspot_voucher: params[:can_manage_hotspot_voucher],
can_manage_hotspot_settings: params[:can_manage_hotspot_settings],
can_read_hotspot_settings: params[:can_read_hotspot_settings],

      

      )

     



      
      
      if params[:send_password_via_sms] == true || params[:send_password_via_sms] == 'true'
        send_login_password(@my_admin.phone_number, @my_admin.password, @my_admin.user_name)
      end
      subdomain = request.headers['X-Subdomain']
company_photo = Account.find_by(subdomain: subdomain).company_setting&.logo&.attached? ? rails_blob_url(Account.find_by(subdomain: subdomain).company_setting.logo, host: 'localhost', protocol: 'http', port: 4000) : nil
      invitation_link = "http://localhost:5173/signin"
      company_name = ActsAsTenant.current_tenant.company_setting.company_name
      # company_photo = ActsAsTenant.current_tenant.company_setting&.logo&.attached? ? rails_blob_url(@company_settings.logo, host: 'localhost', protocol: 'http', port: 4000) : nil
      # if
        
      # end
      #  params[:send_password_via_email] == true 
        
      # end|| params[:send_password_via_email] == 'true'
      subdomain = request.headers['X-Subdomain']
      send_password_via_email= Account.find_by(subdomain: subdomain).admin_setting&.send_password_via_email

if send_password_via_email == true || send_password_via_email == 'true'

        SuperAdminInvitationMailer.super_admins(@my_admin, invitation_link, company_name, company_photo).deliver_now

        
      end

      render json: @my_admin, status: :created
      
    else
      render json: { errors: @my_admin.errors }, status: :unprocessable_entity
      
    end

  
 
  end



  def update
    @my_admin = User.find(params[:id])
    if @my_admin.update!(

      role: params[:role],
      # date_registered: Time.now.strftime('%Y-%m-%d %I:%M:%S %p'),
      can_manage_subscriber: params[:can_manage_subscriber],
      username: params[:username],
      can_read_read_subscriber: params[:can_read_read_subscriber],
      can_manage_ticket_settings: params[:can_manage_ticket_settings],
      can_read_ticket_settings: params[:can_read_ticket_settings],
      can_read_ppoe_package: params[:can_read_ppoe_package],
      can_manage_ppoe_package: params[:can_manage_ppoe_package],
      can_manage_company_setting: params[:can_manage_company_setting],
      can_read_company_setting: params[:can_read_company_setting],
      can_manage_email_setting: params[:can_manage_email_setting],
      can_read_email_setting: params[:can_read_email_setting],
      can_manage_hotspot_packages: params[:can_manage_hotspot_packages],
      can_read_hotspot_packages: params[:can_read_hotspot_packages],
      can_manage_ip_pool: params[:can_manage_ip_pool],
      can_read_ip_pool: params[:can_read_ip_pool],
      can_manage_nas_routers: params[:can_manage_nas_routers],
      can_read_nas_routers: params[:can_read_nas_routers],
      can_manage_router_setting: params[:can_manage_router_setting],
      can_manage_sms:  params[:can_manage_sms],
      can_read_sms:  params[:can_read_sms],
      can_manage_sms_settings: params[:can_manage_sms_settings],
      can_read_sms_settings: params[:can_read_sms_settings],
      can_manage_subscriber_setting: params[:can_manage_subscriber_setting],
      can_read_subscriber_setting: params[:can_read_subscriber_setting],
      can_manage_subscription: params[:can_manage_subscription],
       can_read_subscription: params[:can_read_subscription],
       can_manage_support_tickets: params[:can_manage_support_tickets],
      can_read_support_tickets: params[:can_read_support_tickets],
      can_manage_users: params[:can_manage_users],
       can_read_users: params[:can_read_users],
       can_manage_zones: params[:can_manage_zones],
       can_read_zones: params[:can_read_zones],
can_manage_user_setting: params[:can_manage_user_setting],
can_read_user_setting: params[:can_read_user_setting],
can_read_router_setting: params[:can_read_router_setting],
can_manage_free_radius: params[:can_manage_free_radius],
can_read_free_radius: params[:can_read_free_radius],
can_manage_mpesa_settings: params[:can_manage_mpesa_settings],
can_read_mpesa_settings: params[:can_read_mpesa_settings],
can_reboot_router: params[:can_reboot_router],
can_manage_user_group: params[:can_manage_user_group],
can_read_user_group: params[:can_read_user_group],
can_manage_hotspot_template: params[:can_manage_hotspot_template],
can_read_hotspot_template: params[:can_read_hotspot_template],
can_read_hotspot_voucher: params[:can_read_hotspot_voucher],
can_manage_hotspot_voucher: params[:can_manage_hotspot_voucher],
can_manage_hotspot_settings: params[:can_manage_hotspot_settings],
can_read_hotspot_settings: params[:can_read_hotspot_settings],
    )
      render json: @my_admin, status: :ok
    else
      render json: { errors: @my_admin.errors }, status: :unprocessable_entity
    end
  end
  
def  get_all_admins
@admins = User.all
render json: @admins
end


def delete_user
find_user = User.find_by(id: params[:id])
if find_user
find_user.destroy
render json: { message: 'User deleted successfully' }, status: :ok
else
render json: { error: 'User not found' }, status: :not_found
end

end
  private




  def admin_params
    params.permit(:email, :password, :username, :phone_number,
    
    :can_manage_subscriber,:can_read_read_subscriber,:can_manage_ticket_settings,:can_read_ticket_settings,
  :can_read_ppoe_package,:can_manage_ppoe_package,:can_manage_company_setting,:can_read_company_setting,
  :can_manage_email_setting,:can_read_email_setting,:can_manage_hotspot_packages,:can_read_hotspot_packages,
  :can_manage_ip_pool, :can_read_ip_pool, :can_manage_nas_routers,:can_read_nas_routers,:can_manage_router_setting,
  :can_manage_sms, :can_read_sms, :can_manage_sms_settings, :can_read_sms_settings,:can_manage_subscriber_setting,
  :can_read_subscriber_setting,:can_manage_subscription, :can_read_subscription,:can_read_support_tickets,
  :can_read_support_tickets,:can_manage_users, :can_read_users,:can_manage_zones,:can_read_zones,
  :can_manage_free_radius, :can_read_free_radius,
 :can_manage_mpesa_settings, :can_read_mpesa_settings,
:can_manage_support_tickets,
  :can_manage_user_setting,
  :can_read_user_setting,
  :can_reboot_router,
  :can_read_router_setting,
  :can_manage_user_group,
  :can_read_user_group,
  :can_manage_hotspot_template, :can_read_hotspot_template,
  :can_manage_hotspot_voucher, :can_read_hotspot_voucher,
  :can_manage_hotspot_settings, :can_read_hotspot_settings,



    )
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