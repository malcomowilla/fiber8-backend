class AddAttributeRolesToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_manage_subscriber, :boolean, default: false
    add_column :users, :can_read_read_subscriber, :boolean, default: false
    add_column :users, :can_manage_ticket_settings, :boolean, default: false
    add_column :users, :can_read_ticket_settings, :boolean,   default: false   
    add_column :users, :can_read_ppoe_package, :boolean,  default: false
    add_column :users, :can_manage_ppoe_package, :boolean , default: false
    add_column :users, :can_manage_company_setting, :boolean, default: false
    add_column :users, :can_read_company_setting, :boolean,   default: false
    add_column :users, :can_manage_email_setting, :boolean, default: false
    add_column :users, :can_read_email_setting, :boolean,   default: false
    add_column :users, :can_manage_hotspot_packages, :boolean, default: false
    add_column :users, :can_read_hotspot_packages, :boolean,   default: false
    add_column :users, :can_manage_ip_pool, :boolean,     default: false
    add_column :users, :can_read_ip_pool, :boolean,       default: false
    add_column :users, :can_manage_nas_routers, :boolean, default: false
    add_column :users, :can_read_nas_routers, :boolean,   default: false
    add_column :users, :can_manage_router_setting, :boolean, default: false
    add_column :users, :can_manage_sms, :boolean, default: false
    add_column :users, :can_read_sms, :boolean, default: false
    add_column :users, :can_manage_sms_settings, :boolean, default: false
    add_column :users, :can_read_sms_settings, :boolean, default: false
    add_column :users, :can_manage_subscriber_setting, :boolean, default: false
    add_column :users, :can_read_subscriber_setting, :boolean, default: false
    add_column :users, :can_manage_subscription, :boolean, default: false
    add_column :users, :can_read_subscription, :boolean, default: false
    add_column :users, :can_manage_support_tickets, :boolean, default: false
    add_column :users, :can_read_support_tickets, :boolean, default: false
    add_column :users, :can_manage_users, :boolean, default: false
    add_column :users, :can_read_users, :boolean, default: false
    add_column :users, :can_manage_zones, :boolean, default: false
    add_column :users, :can_read_zones, :boolean, default: false
  end
end
