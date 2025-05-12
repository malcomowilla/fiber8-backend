class AddConditionToHotspotPlan < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_plans, :condition, :boolean
  end
end
