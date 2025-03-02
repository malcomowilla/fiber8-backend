class AddAccountIdAndPackageToHotspotVouchers < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :account_id, :integer
    add_column :hotspot_vouchers, :package, :string
  end
end
