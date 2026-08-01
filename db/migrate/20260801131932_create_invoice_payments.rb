class CreateInvoicePayments < ActiveRecord::Migration[7.2]
   def change
    create_table :invoice_payments do |t|
      t.string   :reference          # M-Pesa TransID / receipt no
      t.string   :phone_number
      t.string   :payer_name
      t.decimal  :amount, precision: 12, scale: 2
      t.datetime :paid_at
      t.string   :status, default: 'completed' 
      t.references :invoice, foreign_key: true
      t.references :account, foreign_key: true 

      t.timestamps
    end

    add_index :invoice_payments, :reference, unique: true
  end
end
