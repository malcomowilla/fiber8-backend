class CreateHotspotBlockedNumbers < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_blocked_numbers do |t|
      t.references :account, null: false, foreign_key: true
      t.string :phone_number, null: false   # normalized: 254XXXXXXXXX
      t.string :reason
      t.string :blocked_by
      t.timestamps
    end

    add_index :hotspot_blocked_numbers, [:account_id, :phone_number], unique: true
  end
end
