json.extract! invoice, :id, :invoice_number, :invoice_date, :due_date, :total, :status, :account_id, :created_at, :updated_at
json.url invoice_url(invoice, format: :json)
