json.extract! activty_log, :id, :action, :subject, :description, :user, :date, :account_id, :created_at, :updated_at
json.url activty_log_url(activty_log, format: :json)
