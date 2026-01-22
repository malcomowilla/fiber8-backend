class CreateSubscriberInvoices < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriber_invoices do |t|
      t.string :item
      t.datetime :due_date
      t.datetime :invoice_date
      t.string :invoice_number
      t.integer :amount
      t.string :status
      t.string :description
      t.string :quantity
      t.integer :account_id

      t.timestamps
    end
  end
end
