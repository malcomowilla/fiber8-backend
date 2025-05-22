json.extract! company_lead, :id, :name, :company_name, :email, :message, :account_id, :created_at, :updated_at
json.url company_lead_url(company_lead, format: :json)
