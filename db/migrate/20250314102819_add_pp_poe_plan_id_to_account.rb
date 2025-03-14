class AddPpPoePlanIdToAccount < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :pp_poe_plan_id, :integer
  end
end
