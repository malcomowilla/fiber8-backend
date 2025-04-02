class AddCanReadAndManageHotspotSettingsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_manage_hotspot_settings, :boolean, default: false
    add_column :users, :can_read_hotspot_settings, :boolean, default: false
  end


  
end












