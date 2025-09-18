class AddLastInvoicedAtToHotspotPlan < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_plans, :last_invoiced_at, :datetime
  end
end
