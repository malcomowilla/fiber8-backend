json.extract! subscriber_invoice, :id, :item, :due_date, :invoice_date, :invoice_number, :amount, :status, :description, :quantity, :account_id, :created_at, :updated_at
json.url subscriber_invoice_url(subscriber_invoice, format: :json)
