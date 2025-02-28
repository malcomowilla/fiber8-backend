class AddDatetimeValuesToHotspotPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :valid_from, :datetime
    add_column :hotspot_packages, :valid_until, :datetime
  end
end
