class AddHotspotPlanIdToAccount < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :hotspot_plan_id, :integer
  end
end
