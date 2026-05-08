json.extract! ip_binding, :id, :router, :name, :package, :mac, :ip, :expiry, :device_type, :account_id, :router_id, :created_at, :updated_at
json.url ip_binding_url(ip_binding, format: :json)
