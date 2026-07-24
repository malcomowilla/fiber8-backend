class CreateDefaultSystemAdSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :default_system_ad_settings do |t|
      t.references :account, null: false, foreign_key: true
      t.string     :ad_id,   null: false   # e.g. 'advertise_with_us'
      t.boolean    :enabled,  default: false
      t.timestamps
    end
    add_index :default_system_ad_settings, [:account_id, :ad_id], unique: true
  end
end
