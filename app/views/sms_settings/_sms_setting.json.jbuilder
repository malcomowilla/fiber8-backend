json.extract! sms_setting, :id, :api_key, :api_secret, :sender_id, :short_code, :username, :accoun_id, :created_at, :updated_at
json.url sms_setting_url(sms_setting, format: :json)
