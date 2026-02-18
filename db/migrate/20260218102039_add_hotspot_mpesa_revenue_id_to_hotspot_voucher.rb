class AddHotspotMpesaRevenueIdToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :hotspot_mpesa_revenue_id, :integer
  end
end
