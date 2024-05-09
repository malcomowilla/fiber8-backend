class RemoveUploadFromPPoePackages < ActiveRecord::Migration[7.1]
  def change
    remove_column :p_poe_packages, :download_burst_limit, :integer
    remove_column :p_poe_packages, :upload_burst_limit, :integer
  end
end
