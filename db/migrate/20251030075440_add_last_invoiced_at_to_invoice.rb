class AddLastInvoicedAtToInvoice < ActiveRecord::Migration[7.2]
  def change
    add_column :invoices, :last_invoiced_at, :datetime
  end
end
