class CalendarEventSerializer < ActiveModel::Serializer
  attributes :id, :event_title, :start_date_time, :end_date_time, :title, :start, :end, :account_id,
  :client, :assigned_to, :status, :task_type

end
