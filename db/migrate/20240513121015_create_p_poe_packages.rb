class CreatePPoePackages < ActiveRecord::Migration[7.1]
  def change
    create_table :p_poe_packages do |t|
      t.string :name
      t.string :price
      t.string :download_limit
      t.string :upload_limit
      t.integer :account_id
      t.string :tx_rate_limit
      t.string :rx_rate_limit
      t.string :validity_period_units
      t.string :download_burst_limit
      t.string :upload_burst_limit
      t.string :validity
      t.string :mikrotik_id

      t.timestamps
    end
  end
end
