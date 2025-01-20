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

# db/migrate/20240420145643_add_download_burst_and_upload_burst_limit_to_p_poe_packages.rb
# 20240513121015_create_p_poe_packages.rb