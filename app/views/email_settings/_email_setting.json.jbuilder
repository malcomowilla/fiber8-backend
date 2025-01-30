json.extract! email_setting, :id, :smtp_host, :smtp_username, :sender_email, :smtp_password, :api_key, :domain, :created_at, :updated_at
json.url email_setting_url(email_setting, format: :json)
