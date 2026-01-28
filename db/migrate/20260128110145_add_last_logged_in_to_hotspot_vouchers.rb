class AddLastLoggedInToHotspotVouchers < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :last_logged_in, :datetime
  end
end
