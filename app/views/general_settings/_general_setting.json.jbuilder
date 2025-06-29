json.extract! general_setting, :id, :title, :timezone, :allowed_ips, :account_id, :created_at, :updated_at
json.url general_setting_url(general_setting, format: :json)
