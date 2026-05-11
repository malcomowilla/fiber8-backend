class AddBurstTimeToHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :burst_time, :integer
  end
end
