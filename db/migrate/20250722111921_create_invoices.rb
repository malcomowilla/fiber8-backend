class CreateInvoices < ActiveRecord::Migration[7.2]
  def change
    create_table :invoices do |t|
      t.string :invoice_number
      t.datetime :invoice_date
      t.datetime :due_date
      t.string :total
      t.string :status
      t.integer :account_id

      t.timestamps
    end
  end
end
