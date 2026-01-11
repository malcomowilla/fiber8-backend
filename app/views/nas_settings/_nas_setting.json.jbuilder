json.extract! nas_setting, :id, :notification_when_unreachable, :unreachable_duration_minutes, :notification_phone_number, :created_at, :updated_at
json.url nas_setting_url(nas_setting, format: :json)
