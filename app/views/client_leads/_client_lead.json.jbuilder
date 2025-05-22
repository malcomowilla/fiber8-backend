json.extract! client_lead, :id, :name, :email, :company_name, :phone_number, :created_at, :updated_at
json.url client_lead_url(client_lead, format: :json)
