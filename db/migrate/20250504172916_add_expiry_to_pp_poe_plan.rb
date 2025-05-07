class AddExpiryToPpPoePlan < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_plans, :expiry, :datetime
  end
end
