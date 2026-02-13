class AddAmountPaidToInvoice < ActiveRecord::Migration[7.2]
  def change
    add_column :invoices, :amount_paid, :integer
  end
end
