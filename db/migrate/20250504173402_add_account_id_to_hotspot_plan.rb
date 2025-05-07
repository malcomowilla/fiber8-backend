class AddAccountIdToHotspotPlan < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_plans, :account_id, :integer
  end
end
