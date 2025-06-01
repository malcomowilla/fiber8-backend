json.extract! change_log, :id, :version, :system_changes, :change_title, :created_at, :updated_at
json.url change_log_url(change_log, format: :json)
