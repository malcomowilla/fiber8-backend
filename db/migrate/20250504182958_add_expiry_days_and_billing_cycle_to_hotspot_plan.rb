class AddExpiryDaysAndBillingCycleToHotspotPlan < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_plans, :expiry_days, :datetime
    add_column :hotspot_plans, :billing_cycle, :string
  end
end
