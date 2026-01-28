class AddMacAndIpToHotspotVouchers < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :mac, :string
    add_column :hotspot_vouchers, :ip, :string
  end
end
