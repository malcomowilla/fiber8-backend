class AddLocationToHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :location, :string
  end
end
