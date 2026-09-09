class CreateHotspotLoyaltyActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_loyalty_activities do |t|
      t.references :account, null: false, foreign_key: true
      t.references :hotspot_loyalty_point, null: false, foreign_key: true
      t.string   :kind, null: false        # 'earn' | 'claim' | 'expire'
      t.integer  :points, null: false      # signed
      t.integer  :balance_after, null: false
      t.decimal  :amount, precision: 12, scale: 2
      t.string   :package
      t.string   :reference                # M-Pesa/Tuma reference, for idempotency
      t.timestamps
    end
    add_index :hotspot_loyalty_activities, [:account_id, :reference, :kind]
  end
end
