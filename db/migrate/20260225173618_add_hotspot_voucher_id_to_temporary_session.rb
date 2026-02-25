class AddHotspotVoucherIdToTemporarySession < ActiveRecord::Migration[7.2]
  def change
    add_column :temporary_sessions, :hotspot_voucher_id, :integer
  end
end
