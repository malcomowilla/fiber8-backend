class AddPermissionAttributesToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_create_lead, :boolean, default: false
    add_column :users, :can_read_lead, :boolean, default: false
    add_column :users, :can_create_calendar_events, :boolean, default: false
    add_column :users, :can_read_calendar_events, :boolean, default: false
    add_column :users, :can_upload_subscriber, :boolean, default: false
    add_column :users, :can_send_bulk_sms, :boolean, default: false
    add_column :users, :can_send_single_sms, :boolean, default: false
    add_column :users, :can_read_ip_networks, :boolean, default: false
    add_column :users, :can_create_ip_networks, :boolean, default: false
    add_column :users, :can_create_wireguard_configuration, :boolean, default: false
    add_column :users, :can_read_task_setting, :boolean, default: false
    add_column :users, :can_create_task_setting, :boolean, default: false
    add_column :users, :can_create_license_setting, :boolean, default: false
    add_column :users, :can_read_license_setting, :boolean, default: false
  end
end
