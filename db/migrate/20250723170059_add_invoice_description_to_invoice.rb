class AddInvoiceDescriptionToInvoice < ActiveRecord::Migration[7.2]
  def change
    add_column :invoices, :invoice_desciption, :string
  end
end
