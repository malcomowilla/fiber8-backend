class CreateHotspotSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_subscriptions do |t|
      t.string :voucher
      t.string :ip_address
      t.string :start_time
      t.string :up_time
      t.string :download
      t.string :upload
      t.integer :account_id

      t.timestamps
    end
  end
end
