class CreateHotspotLoyaltyPoints < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_loyalty_points do |t|
      t.references :account, null: false, foreign_key: true
      t.string   :phone, null: false
      t.string   :name
      t.integer  :balance, default: 0, null: false
      t.integer  :lifetime_earned, default: 0, null: false
      t.integer  :lifetime_spent, default: 0, null: false
      t.decimal  :total_spent_amount, precision: 12, scale: 2, default: 0
      t.integer  :purchase_count, default: 0
      t.string   :last_package
      t.datetime :last_purchase_at
      t.datetime :first_seen_at
      t.datetime :last_claim_at
      t.boolean  :expiry_warning_sent, default: false
      t.timestamps
    end
    add_index :hotspot_loyalty_points, [:account_id, :phone], unique: true
  end
end
