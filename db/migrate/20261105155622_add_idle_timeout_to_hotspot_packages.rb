class AddIdleTimeoutToHotspotPackages < ActiveRecord::Migration[7.2]
 def change
    add_column :hotspot_packages, :idle_timeout_value,   :integer
    add_column :hotspot_packages, :idle_timeout_unit,    :string
    add_column :hotspot_packages, :idle_timeout_seconds, :integer
  end
end
