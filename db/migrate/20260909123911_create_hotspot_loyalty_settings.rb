class CreateHotspotLoyaltySettings < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_loyalty_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.boolean  :enabled, default: false, null: false
      t.decimal  :earn_rate_percent, precision: 5, scale: 2, default: 5.0
      t.integer  :max_points               # nil = no maximum
      t.integer  :expire_after_days, default: 30
      t.integer  :expire_warning_days, default: 2
      t.integer  :expire_min_balance, default: 10
      t.timestamps
    end
  end
end
