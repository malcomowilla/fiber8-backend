class AddPaidOutCheckToHotspotRevenue < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_mpesa_revenues, :paid_out, :boolean, default: false
add_column :hotspot_mpesa_revenues, :paid_out_at, :datetime
  end
end
