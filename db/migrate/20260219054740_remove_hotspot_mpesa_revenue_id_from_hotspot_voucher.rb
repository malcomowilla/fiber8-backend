class RemoveHotspotMpesaRevenueIdFromHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    remove_column :hotspot_vouchers, :hotspot_mpesa_revenue_id, :integer
  end
end
