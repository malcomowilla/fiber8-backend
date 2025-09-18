class AddLastInvoicedAtToAccount < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :last_invoiced_at, :datetime
  end
end
