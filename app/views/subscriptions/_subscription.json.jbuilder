json.extract! subscription, :id, :name, :phone, :package, :status, :last_subscribed, :expiry, :created_at, :updated_at
json.url subscription_url(subscription, format: :json)
