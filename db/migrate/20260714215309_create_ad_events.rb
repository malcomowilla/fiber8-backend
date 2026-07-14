class CreateAdEvents < ActiveRecord::Migration[7.2]
   def change
    create_table :ad_events do |t|
      t.references :ad_setting, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :event_type, null: false # impression | click | video_completed | video_skipped | dismissed
      t.timestamps
    end
    add_index :ad_events, [:ad_setting_id, :event_type]
    add_index :ad_events, [:account_id, :created_at]
  end
end
