json.extract! calendar_event, :id, :event_title, :start_date_time, :end_date_time, :title, :start, :end, :account_id, :created_at, :updated_at
json.url calendar_event_url(calendar_event, format: :json)
