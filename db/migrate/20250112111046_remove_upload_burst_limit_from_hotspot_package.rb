class RemoveUploadBurstLimitFromHotspotPackage < ActiveRecord::Migration[7.1]
  def change
    remove_column :hotspot_packages, :upload_burst_limitmikrotik_id, :string
  end
end
