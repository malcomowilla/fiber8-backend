class AddIndexToNameHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    add_index :hotspot_packages, :name
  end
end
