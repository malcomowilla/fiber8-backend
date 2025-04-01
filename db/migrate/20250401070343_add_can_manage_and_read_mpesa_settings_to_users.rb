class AddCanManageAndReadMpesaSettingsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_manage_mpesa_settings, :boolean, default: false
    add_column :users, :can_read_mpesa_settings, :boolean, default: false
  end
end


