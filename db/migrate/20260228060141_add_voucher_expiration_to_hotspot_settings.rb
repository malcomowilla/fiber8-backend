class AddVoucherExpirationToHotspotSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_settings, :voucher_expiration, :string
  end
end
