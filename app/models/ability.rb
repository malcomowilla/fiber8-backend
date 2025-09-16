class Ability
  include CanCan::Ability
  
  def initialize(admin)
    return unless admin.present?

    Rails.logger.info "Initializing abilities for  admin: #{admin.inspect}"
    


    # can :read, :get_chat_messages if admin.can_read_chats == true
    # can :manage, :create_chat_message if admin.can_manage_chats == true


    # assign_permissions_based_on_flags(admin)
    # 





    
    if admin.role == 'super_administrator' || admin.role == 'Super Administrator' || admin.role == 'super administrator'  || admin.role == 'Super administrator' || admin.role == 'Super Admin' || admin.role == 'super admin' || admin.role == 'Super admin' || admin.role == 'superadmin' || admin.role == 'Superadmin' || admin.role == 'SUPER ADMINISTRATOR' || admin.role == 'SUPER ADMIN'
      can :manage, :all
      can :read, :all
      can :reboot_router, NasRouter

      
    elsif admin.role == 'system_administrator'
    can :manage, :all
    can :read, :all
    can :reboot_router, NasRouter


    elsif admin.role == 'customer_support'
      can :manage,  SupportTicket
      can :read, Subscriber


    elsif admin.role == 'agent'
      can :manage,  SupportTicket
      can :read, Subscriber


    else
      assign_permissions_based_on_flags(admin)
      Rails.logger.info "Super administrator can manage and read all"
    # elsif admin.role == 'administrator'  
    #   can :manage, Payment
    #   can :manage, Customer
    #   can :manage, Store
    #   can :manage, StoreManager
    #   can :manage, Location
    #   can :manage, SubLocation
    #   can :manage, ServiceProvider
    #   can :manage,  SupportTicket
    #   can :manage, CalendarEvent

      # Rails.logger.info "Administrator can manage specific resources"
      # elsif admin.role == 'store_manager'
      #   can :manage, Store
      #   can :manage,  StoreManager
      #   can :manage, Location 
      #   can :manage, SubLocation

      # elsif admin.role == 'agent'
      #   can :manage, SupportTicket
      #   can :read, SupportTicket
      #   can :read, Customer
      # elsif admin.role == 'customer'
      #   can :manage, CalendarEvent  
      #   can :read, CalendarEvent

      # elsif admin.role == 'customer_support'
      #   can :manage, SupportTicket
      #   can :read, SupportTicket
        # can :read, Customer

        

    #     cannot :read, :get_settings_for_store_manager 
    # cannot :read, :get_settings_for_store 
    # cannot :read, :get_settings_for_provider 
    # canotn :read, :get_settings_for_customer 
    # cannot :read, :get_admin_settings 


    # can :manage, :create_for_customer if admin.can_manage_settings
    # can :manage, :create_for_store if admin.can_manage_settings
    # can :manage, :create_for_provider if admin.can_manage_settings
    # can :manage, :create_admin_settings if admin.can_manage_settings
    # can :manage, :create_for_store_manager if admin.can_manage_settings
    end


  end

  private

  def assign_permissions_based_on_flags(admin)
    Rails.logger.info "Assigning permissions based on flags for admin: #{admin.inspect}"

    # create_for_customer
    # create_for_store
    # create_for_provider
    # create_admin_settings
    # create_for_store_manager
    







#     can :read, :get_settings_for_store_manager if admin.can_read_settings 
#     can :read, :get_settings_for_tickets if admin.can_read_settings
#     can :read, :get_settings_for_store if admin.can_read_settings 
#     can :read, :get_settings_for_provider if admin.can_read_settings
#     can :read, :get_settings_for_customer if admin.can_read_settings 
#     can :read, :get_admin_settings if admin.can_read_settings 
#     can :read, :get_sms_balance if admin.can_read_sms
#     can :read, :get_sms_balance if admin.can_manage_sms
#     can :read, :get_all_sms if admin.can_read_sms
#     can :read, :get_calendar_settings if admin.can_read_settings
#     can :read, :get_chat_messages if admin.can_read_chats 
#     can :read, :get_chat_messages if admin.can_manage_chats 
#     can :manage, :create_chat_message if admin.can_manage_chats 

# can :read, :customer_stats if admin.can_read_customer_stats

# can :read, :service_provider_stats if admin.can_read_service_provider_stats
# can :manage, :send_individual if admin.can_manage_individual_email


#     can :read, :get_calendar_settings if admin.can_manage_settings
#     can :read, :get_settings_for_store_manager if admin.can_manage_settings 
#     can :read, :get_settings_for_store if admin.can_manage_settings 
#     can :read, :get_settings_for_provider if admin.can_manage_settings
#     can :read, :get_settings_for_customer if admin.can_manage_settings 
#     can :read, :get_admin_settings if admin.can_manage_settings 
#     can :read, :get_settings_for_tickets if admin.can_manage_settings
    

#     can :manage, :create_for_customer if admin.can_manage_settings
#     can :manage, :create_for_store if admin.can_manage_settings
#     can :manage, :create_for_provider if admin.can_manage_settings
#     can :manage, :create_admin_settings if admin.can_manage_settings
#     can :manage, :create_for_store_manager if admin.can_manage_settings
#     can :manage, :create_for_tickets if admin.can_manage_settings
#     can :manage, :create_calendar_settings if admin.can_manage_settings

    # t.string "can_manage_calendar"
    # t.string "can_read_calendar"





    # ,:can_read_ticket_settings,
    # :can_read_ppoe_package,:can_manage_ppoe_package,:can_manage_company_setting,:can_read_company_setting,
    # :can_manage_email_setting,:can_read_email_setting,:can_manage_hotspot_packages,:can_read_hotspot_packages,
    # :can_manage_ip_pool, :can_read_ip_pool, :can_manage_nas_routers,:can_read_nas_routers,:can_manage_router_setting,
    # :can_manage_sms, :can_read_sms, :can_manage_sms_settings, :can_read_sms_settings,:can_manage_subscriber_setting,
    # :can_read_subscriber_setting,:can_manage_subscription, :can_read_subscription,:can_read_support_tickets,
    # :can_read_support_tickets,:can_manage_users, :can_read_users,:can_manage_zones,:can_read_zones
  


    
    # Rails.logger.info "can_read_settings: #{admin.can_read_settings}"

    can :manage, Subscriber if admin.can_manage_subscriber
    can :read, Subscriber if admin.can_read_read_subscriber

    can :manage, CompanySetting if admin.can_manage_company_setting
    can :read, CompanySetting if admin.can_read_company_setting
      

    can :manage, EmailSetting if admin.can_manage_email_setting
    can :read, EmailSetting if admin.can_read_email_setting
    can :reboot_router, NasRouter if admin.can_reboot_router

    can :manage, HotspotPackage if admin.can_manage_hotspot_packages
    can :read, HotspotPackage if admin.can_read_hotspot_packages
    
    can :manage, Sm if admin.can_manage_sms
    can :read, Sm if admin.can_read_sms
    # can :read, SmsTemplate if admin.can_read_sms_templates
    # can :manage, SmsTemplate if admin.can_manage_sms_templates
    can :manage, SupportTicket if admin.can_manage_support_tickets
    can :read, SupportTicket if admin.can_read_support_tickets
   

can :manage, RouterSetting if admin.can_manage_router_setting
can :read, RouterSetting if admin.can_read_router_setting
  

can :manage, Package if admin.can_manage_ppoe_package
can :read, Package if admin.can_read_ppoe_package


can :manage, IpPool if admin.can_manage_ip_pool
can :read, IpPool if admin.can_read_ip_pool


can :manage, NasRouter if admin.can_manage_nas_routers
can :read, NasRouter if admin.can_read_nas_routers
  

can :manage, SubscriberSetting if admin.can_manage_subscriber_setting
can :read, SubscriberSetting if admin.can_read_subscriber_setting
  
can :manage, SmsSetting if admin.can_manage_sms_settings
can :read, SmsSetting if admin.can_read_sms_settings

can :manage, HotspotMpesaSetting if admin.can_manage_mpesa_settings
can :read, HotspotMpesaSetting if admin.can_read_mpesa_settings

can :manage, Na if admin.can_manage_free_radius
can :read, Na if admin.can_read_free_radius


can :manage, HotspotTemplate if admin.can_manage_hotspot_template
can :read, HotspotTemplate if admin.can_read_hotspot_template


can :manage, HotspotVoucher if admin.can_manage_hotspot_voucher
can :read, HotspotVoucher if admin.can_read_hotspot_voucher

    can :manage, TicketSetting if admin.can_manage_ticket_settings
    can :read, TicketSetting if admin.can_read_ticket_settings

can :manage, Invoice if admin.can_manage_invoice
can :read, Invoice if admin.can_read_invoice

    can :manage, HotspotSetting if admin.can_manage_hotspot_settings
    can :read, HotspotSetting if admin.can_read_hotspot_settings

# can :manage, CalendarEvent if admin.can_manage_calendar
# can :read, CalendarEvent if admin.can_read_calendar
can :manage, Equipment if admin.can_manage_equipment
can :read, Equipment if admin.can_read_equipment
 
can :generate_config, WireguardPeer if admin.can_create_wireguard_configuration

can :delete_user, User if admin.can_manage_users
can :get_all_admins, User if admin.can_read_users
can :invite_users, User if admin.can_manage_users
can :update, User if admin.can_manage_users

can :import, Subscriber if admin.can_upload_subscriber

can :manage, UserGroup if  admin.can_manage_user_group
can :read, UserGroup if admin.can_read_user_group

    can :manage, User if admin.can_manage_users
    can :read, User if admin.can_read_users

    # can :manage, GeneralSetting if admin.can_manage_settings

    can :manage, Subscription if admin.can_manage_subscription
    can :read, Subscription if admin.can_read_subscription

    can :manage, CalendarEvent if admin.can_create_calendar_events
    can :read, CalendarEvent if admin.can_read_calendar_events

    can :manage, WireguardPeer if admin.can_manage_private_ips
    can :read, WireguardPeer if admin.can_read_private_ips

    can :manage, ClientLead if admin.can_create_lead
    can :read, ClientLead if admin.can_read_lead
    can :manage, IpNetwork if admin.can_manage_networks
    can :read, IpNetwork if admin.can_read_networks
    # can :manage, Location if admin.can_manage_location
    # can :read, Location if admin.can_read_location
    # cannot :manage, SubLocation if admin.can_manage_sub_location == false
    # can :manage, SubLocation if admin.can_manage_sub_location 
    # can :read, SubLocation if admin.can_read_sub_location

    # can :manage, Invoice if admin.can_manage_invoice
    # can :read, Invoice if admin.can_read_invoice

    # can :manage, FinancesAndAccount if admin.can_manage_finances_account
    # can :read, FinancesAndAccount if admin.can_read_finances_account
  end
end





