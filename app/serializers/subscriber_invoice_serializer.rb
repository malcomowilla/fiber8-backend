class SubscriberInvoiceSerializer < ActiveModel::Serializer
  attributes :id, :item, :due_date, :invoice_date, :invoice_number, :amount, :status, :description, :quantity, :account_id
end
