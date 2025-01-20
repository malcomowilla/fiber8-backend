class AddIdToHotspotPackage < ActiveRecord::Migration[7.1]
  def change
    add_column :hotspot_packages, :profile_id, :string
    add_column :hotspot_packages, :limitation_id, :string
    add_column :hotspot_packages, :profile_limitation_id, :string
  end
end
