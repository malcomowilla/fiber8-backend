class ChangeExpiryDaysToIntegerHotspot < ActiveRecord::Migration[7.2]
  def change
     remove_column :hotspot_plans, :expiry_days
    add_column :hotspot_plans, :expiry_days, :integer, default: 3
    
  end
end
