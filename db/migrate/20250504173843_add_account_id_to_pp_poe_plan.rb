class AddAccountIdToPpPoePlan < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_plans, :account_id, :integer
  end
end
