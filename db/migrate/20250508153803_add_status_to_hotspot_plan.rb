class AddStatusToHotspotPlan < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_plans, :status, :string
  end
end
