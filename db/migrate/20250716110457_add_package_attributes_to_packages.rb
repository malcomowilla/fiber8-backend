class AddPackageAttributesToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :daily_charge, :string
    add_column :packages, :burst_upload_speedburst_download_speed, :string
    add_column :packages, :burst_threshold_download, :string
    add_column :packages, :burst_threshold_upload, :string
    add_column :packages, :burst_time, :string
  end
end
