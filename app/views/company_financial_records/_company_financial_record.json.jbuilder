json.extract! company_financial_record, :id, :category, :is_intercompany, :amount, :description, :transaction_type, :company, :date, :counterparty, :account_id, :created_at, :updated_at
json.url company_financial_record_url(company_financial_record, format: :json)
