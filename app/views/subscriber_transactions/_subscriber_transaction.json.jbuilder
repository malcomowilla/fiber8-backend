json.extract! subscriber_transaction, :id, :type, :credit, :debit, :date, :title, :description, :account_id, :created_at, :updated_at
json.url subscriber_transaction_url(subscriber_transaction, format: :json)
