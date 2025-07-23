class ChangeExpiryDaysToInteger < ActiveRecord::Migration[7.2]
  def change
     remove_column :pp_poe_plans, :expiry_days
    add_column :pp_poe_plans, :expiry_days, :integer, default: 3
    
  end
end
