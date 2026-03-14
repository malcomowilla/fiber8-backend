class AddIsOnlineToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :is_online, :boolean
  end
end
