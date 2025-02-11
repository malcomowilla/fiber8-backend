json.extract! admin_setting, :id, :enable_2fa_for_admin_sms, :enable_2fa_for_admin_email, :send_password_via_sms, :send_password_via_email, :check_inactive_days, :check_inactive_hrs, :check_inactive_minutes, :enable_2fa_for_admin_passkeys, :account_id, :user_id, :created_at, :updated_at
json.url admin_setting_url(admin_setting, format: :json)
