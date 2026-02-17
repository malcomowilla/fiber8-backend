class AddUsedVoucherToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :used_voucher, :boolean, default: false
  end
end


