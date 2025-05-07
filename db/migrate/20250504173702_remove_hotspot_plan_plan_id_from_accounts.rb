class RemoveHotspotPlanPlanIdFromAccounts < ActiveRecord::Migration[7.2]
  def change
    remove_column :accounts, :hotspot_plan_id, :integer
  end
end
