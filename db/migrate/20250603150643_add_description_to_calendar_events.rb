class AddDescriptionToCalendarEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :calendar_events, :description, :string
  end
end
