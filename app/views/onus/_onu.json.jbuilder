json.extract! onu, :id, :serial_number, :oui, :product_class, :manufacturer, :onu_id, :status, :last_inform, :account_id, :last_boot, :created_at, :updated_at
json.url onu_url(onu, format: :json)
