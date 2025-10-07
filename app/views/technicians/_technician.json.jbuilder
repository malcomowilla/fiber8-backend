json.extract! technician, :id, :email, :username, :phone_number, :password_digest, :account_id, :created_at, :updated_at
json.url technician_url(technician, format: :json)
