class InvoiceSerializer < ActiveModel::Serializer
  attributes :id, :invoice_number, :invoice_date, :due_date, :total, :status, :account_id
end
