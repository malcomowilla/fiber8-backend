class AddHotspotPackageIdToHotspotVoucher < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :hotspot_package_id, :integer
  end
end
