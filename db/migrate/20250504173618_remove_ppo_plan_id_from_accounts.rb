class RemovePpoPlanIdFromAccounts < ActiveRecord::Migration[7.2]
  def change
    remove_column :accounts, :pp_poe_plan_id, :integer
  end
end
