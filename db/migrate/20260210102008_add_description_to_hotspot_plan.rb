class AddDescriptionToHotspotPlan < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_plans, :description, :string, default: "4% of hotspot revenue"
  end
end
