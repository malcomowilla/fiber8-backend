class AddTaskTypeStatusAssignClientToCalendarEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :calendar_events, :client, :string
    add_column :calendar_events, :assigned_to, :string
    add_column :calendar_events, :task_type, :string
    add_column :calendar_events, :status, :string
  end
end
