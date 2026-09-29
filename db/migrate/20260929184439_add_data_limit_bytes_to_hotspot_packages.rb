class AddDataLimitBytesToHotspotPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :data_limit_bytes, :bigint
  end
end
