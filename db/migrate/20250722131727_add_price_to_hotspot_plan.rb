class AddPriceToHotspotPlan < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_plans, :price, :string
  end
end
