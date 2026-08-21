class CreatePaystackSettings < ActiveRecord::Migration[7.2]
   def change
    create_table :paystack_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string  :public_key
      t.string  :secret_key
      t.boolean :enabled,           default: false, null: false
      t.boolean :use_for_hotspot,   default: false, null: false
      t.boolean :use_for_tv_plans,  default: false, null: false
      t.jsonb   :ip_whitelist,      default: []
      t.timestamps
    end
  end
end
