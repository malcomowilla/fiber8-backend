class Ability
  include CanCan::Ability
  
  def initialize(admin)
    return unless admin.present?

    Rails.logger.info "Initializing abilities for  admin: #{admin.inspect}"
    


    # can :read, :get_chat_messages if admin.can_read_chats == true
    # can :manage, :create_chat_message if admin.can_manage_chats == true


    # assign_permissions_based_on_flags(admin)
    
    if admin.role == 'super_administrator'
      can :manage, :all
      can :read, :all
      

      
    elsif admin.role == 'system_administrator'
    can :manage, :all
    can :read, :all


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
    



    can :read, :get_settings_for_store_manager if admin.can_read_settings 
    can :read, :get_settings_for_tickets if admin.can_read_settings
    can :read, :get_settings_for_store if admin.can_read_settings 
    can :read, :get_settings_for_provider if admin.can_read_settings
    can :read, :get_settings_for_customer if admin.can_read_settings 
    can :read, :get_admin_settings if admin.can_read_settings 
    can :read, :get_sms_balance if admin.can_read_sms
    can :read, :get_sms_balance if admin.can_manage_sms
    can :read, :get_all_sms if admin.can_read_sms
    can :read, :get_calendar_settings if admin.can_read_settings
    can :read, :get_chat_messages if admin.can_read_chats 
    can :read, :get_chat_messages if admin.can_manage_chats 
    can :manage, :create_chat_message if admin.can_manage_chats 

can :read, :customer_stats if admin.can_read_customer_stats

can :read, :service_provider_stats if admin.can_read_service_provider_stats
can :manage, :send_individual if admin.can_manage_individual_email


    can :read, :get_calendar_settings if admin.can_manage_settings
    can :read, :get_settings_for_store_manager if admin.can_manage_settings 
    can :read, :get_settings_for_store if admin.can_manage_settings 
    can :read, :get_settings_for_provider if admin.can_manage_settings
    can :read, :get_settings_for_customer if admin.can_manage_settings 
    can :read, :get_admin_settings if admin.can_manage_settings 
    can :read, :get_settings_for_tickets if admin.can_manage_settings
    

    can :manage, :create_for_customer if admin.can_manage_settings
    can :manage, :create_for_store if admin.can_manage_settings
    can :manage, :create_for_provider if admin.can_manage_settings
    can :manage, :create_admin_settings if admin.can_manage_settings
    can :manage, :create_for_store_manager if admin.can_manage_settings
    can :manage, :create_for_tickets if admin.can_manage_settings
    can :manage, :create_calendar_settings if admin.can_manage_settings

    # t.string "can_manage_calendar"
    # t.string "can_read_calendar"


    Rails.logger.info "can_read_settings: #{admin.can_read_settings}"

    can :manage, Payment if admin.can_manage_payment
    can :read, Payment if admin.can_read_payment
    can :manage, Sm if admin.can_manage_sms
    can :read, Sm if admin.can_read_sms
    can :read, SmsTemplate if admin.can_read_sms_templates
    can :manage, SmsTemplate if admin.can_manage_sms_templates
    can :manage, SupportTicket if admin.can_manage_tickets
    can :read, SupportTicket if admin.can_read_tickets 


can :manage, CalendarEvent if admin.can_manage_calendar
can :read, CalendarEvent if admin.can_read_calendar

 


    can :manage, Admin if admin.can_manage_user
    can :read, Admin if admin.can_read_user

    can :manage, GeneralSetting if admin.can_manage_settings

    can :manage, Customer if admin.can_manage_customers
    can :read, Customer if admin.can_read_customers

    can :manage, ServiceProvider if admin.can_manage_service_provider
    can :read, ServiceProvider if admin.can_read_service_provider

    can :manage, Store if admin.can_manage_store
    can :read, Store if admin.can_read_store

    can :manage, StoreManager if admin.can_manage_store_manager
    can :read, StoreManager if admin.can_read_store_manager

    can :manage, Location if admin.can_manage_location
    can :read, Location if admin.can_read_location
    cannot :manage, SubLocation if admin.can_manage_sub_location == false
    can :manage, SubLocation if admin.can_manage_sub_location 
    can :read, SubLocation if admin.can_read_sub_location

    # can :manage, Invoice if admin.can_manage_invoice
    # can :read, Invoice if admin.can_read_invoice

    can :manage, FinancesAndAccount if admin.can_manage_finances_account
    can :read, FinancesAndAccount if admin.can_read_finances_account
  end
end
