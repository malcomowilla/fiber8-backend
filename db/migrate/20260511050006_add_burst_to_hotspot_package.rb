class AddBurstToHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :burst_enabled, :boolean, default: false
    add_column :hotspot_packages, :burst_limit_download, :string
    add_column :hotspot_packages, :burst_limit_upload, :string
    add_column :hotspot_packages, :burst_threshold_download, :string
    add_column :hotspot_packages, :burst_threshold_upload, :string
    add_column :hotspot_packages, :burst_time, :string
  end
end
