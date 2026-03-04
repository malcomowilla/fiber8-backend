class AddIndexToAccountIdHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_index :hotspot_vouchers, :account_id
  end
end
