class CreateHotspotPackages < ActiveRecord::Migration[7.1]
  def change
    create_table :hotspot_packages do |t|
      t.string :name
      t.string :price
      t.string :download_limit
      t.string :upload_limit
      t.integer :account_id
      t.string :tx_rate_limit
      t.string :rx_rate_limit
      t.string :validity_period_units
      t.string :download_burst_limit
      t.integer :upload_burst_limitmikrotik_id
      t.integer :validity

      t.timestamps
    end
  end
end
