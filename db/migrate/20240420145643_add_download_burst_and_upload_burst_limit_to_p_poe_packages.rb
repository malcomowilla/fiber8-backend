class AddDownloadBurstAndUploadBurstLimitToPPoePackages < ActiveRecord::Migration[7.1]
  def change
    add_column :p_poe_packages, :download_burst_limit, :integer
    add_column :p_poe_packages, :upload_burst_limit, :integer
  end
end
