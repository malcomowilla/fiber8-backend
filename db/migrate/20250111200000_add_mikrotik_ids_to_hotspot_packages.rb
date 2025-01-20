class AddMikrotikIdsToHotspotPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :hotspot_packages, :profile_id, :integer
    add_column :hotspot_packages, :limitation_id, :integer
    add_column :hotspot_packages, :profile_limitation_id, :integer
  end
end
