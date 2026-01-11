class CreateNasSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :nas_settings do |t|
      t.boolean :notification_when_unreachable
      t.string :unreachable_duration_minutes
      t.string :notification_phone_number

      t.timestamps
    end
  end
end
