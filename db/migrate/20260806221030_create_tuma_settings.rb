class CreateTumaSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :tuma_settings do |t|
      t.references :account, null: false, index: { unique: true }
      t.string :business_email
      t.string :api_key
      t.string :cached_token
      t.datetime :token_expires_at
      t.boolean :enabled, default: false
      t.boolean :use_for_hotspot, default: false
      t.boolean :use_for_tv_plans, default: false
      t.timestamps
    end
  end
end
