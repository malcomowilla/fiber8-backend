class AddDeviceTypeToHotspotPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :intended_device_type, :string
    
    add_column :hotspot_packages, :device_icon, :string
  end
end
