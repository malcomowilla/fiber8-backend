# app/models/invoice_payment.rb
class InvoicePayment < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :invoice
  belongs_to :account
end