json.extract! hotspot_package, :id, :name, :price, :download_limit, :upload_limit, :account_id, :tx_rate_limit, :rx_rate_limit, :validity_period_units, :download_burst_limit, :upload_burst_limitmikrotik_id, :validity, :created_at, :updated_at
json.url hotspot_package_url(hotspot_package, format: :json)
