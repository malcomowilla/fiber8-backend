json.extract! system_admin_email_setting, :id, :smtp_host, :smtp_username, :sender_email, :smtp_password, :api_keydomain, :system_admin_id, :created_at, :updated_at
json.url system_admin_email_setting_url(system_admin_email_setting, format: :json)
