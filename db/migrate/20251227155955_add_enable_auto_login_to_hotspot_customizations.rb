class AddEnableAutoLoginToHotspotCustomizations < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_customizations, :enable_autologin, :boolean
  end
end
