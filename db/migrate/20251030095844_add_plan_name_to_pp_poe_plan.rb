class AddPlanNameToPpPoePlan < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_plans, :plan_name, :string
  end
end
