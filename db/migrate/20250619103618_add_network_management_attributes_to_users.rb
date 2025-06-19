class AddNetworkManagementAttributesToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_manage_networks, :boolean, default: false
    add_column :users, :can_read_networks, :boolean, default: false
    add_column :users, :can_manage_private_ips, :boolean, default: false
    add_column :users, :can_read_private_ips, :boolean, default: false
  end
end



