json.extract! event_title, :id, :start_date_time, :end_date_time, :title, :start, :end, :account_id, :created_at, :updated_at
json.url event_title_url(event_title, format: :json)
