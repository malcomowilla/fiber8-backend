class CreateHotspotSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_settings do |t|
      t.string :phone_number
      t.string :hotspot_name
      t.string :hotspot_info
      t.string :hotspot_banner
      t.integer :account_id

      t.timestamps
    end
  end
end
