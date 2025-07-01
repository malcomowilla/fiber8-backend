json.extract! customer_portal, :id, :username, :password, :account_id, :created_at, :updated_at
json.url customer_portal_url(customer_portal, format: :json)
