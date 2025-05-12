class AddExpiryToHotspotPlans < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_plans, :expiry, :datetime
  end
end
