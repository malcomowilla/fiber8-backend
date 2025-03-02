class CreateHotspotVouchers < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_vouchers do |t|
      t.string :voucher
      t.string :status
      t.datetime :expiration
      t.string :speed_limit
      t.string :phone

      t.timestamps
    end
  end
end
