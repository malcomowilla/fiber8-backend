class AddEnabledToHotspotPackages < ActiveRecord::Migration[7.2]
 def change
    add_column :hotspot_packages, :enabled, :boolean, default: true, null: false
    add_index :hotspot_packages, :enabled
  end
end
