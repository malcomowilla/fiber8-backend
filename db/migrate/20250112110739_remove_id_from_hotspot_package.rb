class RemoveIdFromHotspotPackage < ActiveRecord::Migration[7.1]
  def change
    remove_column :hotspot_packages, :profile_id, :integer
    remove_column :hotspot_packages, :limitation_id, :integer
    remove_column :hotspot_packages, :profile_limitation_id, :integer
  end
end
