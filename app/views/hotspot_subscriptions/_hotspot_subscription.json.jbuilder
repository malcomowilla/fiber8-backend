json.extract! hotspot_subscription, :id, :voucher, :ip_address, :start_time, :up_time, :download, :upload, :account_id, :created_at, :updated_at
json.url hotspot_subscription_url(hotspot_subscription, format: :json)
