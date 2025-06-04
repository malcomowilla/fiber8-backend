class CreateCalendarSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :calendar_settings do |t|
      t.string :start_in_hours
      t.string :start_in_minutes
      t.integer :account_id

      t.timestamps
    end
  end
end
