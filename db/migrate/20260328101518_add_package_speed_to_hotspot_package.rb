class AddPackageSpeedToHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :package_speed, :string
  end
end
