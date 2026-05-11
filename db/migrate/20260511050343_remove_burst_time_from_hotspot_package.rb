class RemoveBurstTimeFromHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    remove_column :hotspot_packages, :burst_time, :string
  end
end
