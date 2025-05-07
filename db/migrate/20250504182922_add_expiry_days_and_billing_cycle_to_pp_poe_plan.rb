class AddExpiryDaysAndBillingCycleToPpPoePlan < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_plans, :expiry_days, :datetime
    add_column :pp_poe_plans, :billing_cycle, :string
  end
end
