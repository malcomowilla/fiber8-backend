json.extract! company_setting, :id, :company_name, :email_info, :contact_info, :agent_email, :customer_support_phone_number, :customer_support_email, :created_at, :updated_at
json.url company_setting_url(company_setting, format: :json)
