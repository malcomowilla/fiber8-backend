json.extract! equipment, :id, :user, :type, :name, :model, :serial_number, :price, :amount_paid, :account_number, :created_at, :updated_at
json.url equipment_url(equipment, format: :json)
