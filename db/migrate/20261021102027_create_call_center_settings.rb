class CreateCallCenterSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :call_center_settings do |t|
      t.references :account, null: false, index: { unique: true }
      t.boolean :always_open, null: false, default: false
      t.string  :open_days, null: false, default: "mon,tue,wed,thu,fri"
      t.string  :open_from, null: false, default: "08:00"
      t.string  :open_until, null: false, default: "17:00"
      t.string  :timezone, null: false, default: "Africa/Nairobi"
      t.text    :open_message
      t.text    :closed_message
      t.text    :hold_message
      t.string  :hold_music_url
      t.boolean :record_calls, null: false, default: false
      t.boolean :announce_recording, null: false, default: false
      t.timestamps
    end
  end
end
