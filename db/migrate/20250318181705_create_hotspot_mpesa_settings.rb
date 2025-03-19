class CreateHotspotMpesaSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_mpesa_settings do |t|
      t.string :account_type
      t.string :short_code
      t.string :consumer_key
      t.string :consumer_secret
      t.string :passkey
      t.integer :account_id

      t.timestamps
    end
  end
end
