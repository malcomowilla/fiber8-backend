class CreateHotspotBypassSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_bypass_settings do |t|
      t.integer :account_id

      t.timestamps
    end
  end
end
