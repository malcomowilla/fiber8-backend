class AddPackageAttributeToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :burst_upload_speed, :string
    add_column :packages, :burst_download_speed, :string
  end
end
