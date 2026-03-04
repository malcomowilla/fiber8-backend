class AddIndexToVoucherHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_index :hotspot_vouchers, :voucher, unique: true
  end
end
