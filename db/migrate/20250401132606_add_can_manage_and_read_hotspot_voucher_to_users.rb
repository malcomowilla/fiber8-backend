class AddCanManageAndReadHotspotVoucherToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_manage_hotspot_voucher, :boolean, default: false
    add_column :users, :can_read_hotspot_voucher, :boolean, default: false
  end
end
