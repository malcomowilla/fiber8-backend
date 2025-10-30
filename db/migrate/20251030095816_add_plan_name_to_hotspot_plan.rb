class AddPlanNameToHotspotPlan < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_plans, :plan_name, :string
  end
end
