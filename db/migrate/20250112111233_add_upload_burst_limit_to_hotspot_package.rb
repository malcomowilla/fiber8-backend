class AddUploadBurstLimitToHotspotPackage < ActiveRecord::Migration[7.1]
  def change
    add_column :hotspot_packages, :upload_burst_limit, :string
  end
end
