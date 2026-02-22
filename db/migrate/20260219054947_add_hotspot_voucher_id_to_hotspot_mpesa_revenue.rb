class AddHotspotVoucherIdToHotspotMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_mpesa_revenues, :hotspot_voucher_id, :integer
  end
end

