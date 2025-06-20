class UserSerializer < ActiveModel::Serializer
  attributes :username, :email, :id, :created_at, :updated_at, :phone_number, :role,
  :can_manage_subscriber,:can_read_read_subscriber,:can_manage_ticket_settings,:can_read_ticket_settings,
  :can_read_ppoe_package,:can_manage_ppoe_package,:can_manage_company_setting,:can_read_company_setting,
  :can_manage_email_setting,:can_read_email_setting,:can_manage_hotspot_packages,:can_read_hotspot_packages,
  :can_manage_ip_pool, :can_read_ip_pool, :can_manage_nas_routers,:can_read_nas_routers,:can_manage_router_setting,
  :can_manage_sms, :can_read_sms, :can_manage_sms_settings, :can_read_sms_settings,:can_manage_subscriber_setting,
  :can_read_subscriber_setting,:can_manage_subscription, :can_read_subscription,:can_read_support_tickets,
  :can_read_support_tickets,:can_manage_users, :can_read_users,:can_manage_zones,:can_read_zones,
  :can_manage_support_tickets,
  :can_manage_free_radius, :can_read_free_radius, :can_manage_mpesa_settings, :can_read_mpesa_settings,
:can_reboot_router,:can_manage_user_group, :can_read_user_group,
:can_manage_hotspot_template, :can_read_hotspot_template,
:can_manage_hotspot_voucher, :can_read_hotspot_voucher,
:can_manage_hotspot_settings, :can_read_hotspot_settings,
:date_registered, :last_login_at,

:status,
  :can_manage_user_setting,
  :can_read_user_setting,
  :can_read_router_setting,

:can_create_wireguard_configuration,
:can_create_lead,
:can_read_lead,
:can_create_calendar_events,
:can_read_calendar_events,
:can_upload_subscriber,
:can_send_bulk_sms,
:can_send_single_sms,
:can_read_ip_networks,
:can_create_ip_networks,
:can_create_wireguard_configuration,
:can_read_task_setting,
:can_create_task_setting,
:can_create_license_setting,
:can_read_license_setting,
:can_manage_networks,
:can_read_networks,
:can_manage_private_ips,
:can_read_private_ips
  

  

  attribute :welcome_back_message, if: :include_welcome_back_message?
 
  
  def date_registered
    object.date_registered.strftime("%B %d, %Y at %I:%M %p") if object.date_registered.present?
  end




  def last_login_at
    object.last_login_at.strftime("%B %d, %Y at %I:%M %p") if object.last_login_at.present?
  end
  

  def include_welcome_back_message?
    context_present? && instance_options[:context][:welcome_back_message] == false
  end


  def context_present?
    instance_options[:context].present?
  end

  def welcome_back_message
    "Welcome Back"
  end
  
  


end

