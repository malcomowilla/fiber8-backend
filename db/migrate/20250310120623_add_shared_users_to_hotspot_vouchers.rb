class AddSharedUsersToHotspotVouchers < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :shared_users, :string
  end
end
