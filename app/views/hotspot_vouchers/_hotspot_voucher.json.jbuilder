json.extract! hotspot_voucher, :id, :voucher, :status, :expiration, :speed_limit, :phone, :created_at, :updated_at
json.url hotspot_voucher_url(hotspot_voucher, format: :json)
