class AddVoucherExpirationToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :voucher_expiration, :string
  end
end
