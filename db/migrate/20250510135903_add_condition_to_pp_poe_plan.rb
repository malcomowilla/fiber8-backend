class AddConditionToPpPoePlan < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_plans, :condition, :boolean
  end
end
