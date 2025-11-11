class CreateAnalyticsEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :analytics_events do |t|
      t.string :event_type
      t.string :details
      t.datetime :timestamp
      t.integer :account_id

      t.timestamps
    end
  end
end
