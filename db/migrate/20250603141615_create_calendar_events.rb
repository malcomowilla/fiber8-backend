class CreateCalendarEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :calendar_events do |t|
      t.string :event_title
      t.datetime :start_date_time
      t.datetime :end_date_time
      t.string :title
      t.datetime :start
      t.datetime :end
      t.integer :account_id

      t.timestamps
    end
  end
end
