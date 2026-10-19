class CreateLimitPayments < ActiveRecord::Migration[7.2]
   def change
    create_table :limit_payments do |t|
      t.string  :id_number, null: false
      t.string  :phone, null: false
      t.integer :new_limit, null: false
      t.integer :amount, null: false
      t.string  :external_reference, null: false
      t.string  :payhero_reference
      t.string  :checkout_request_id
      t.string  :mpesa_receipt
      t.string  :status, null: false, default: 'pending'
      t.string  :result_desc
      t.json    :callback_payload
      t.datetime :paid_at
      t.timestamps
    end

    add_index :limit_payments, :external_reference, unique: true
    add_index :limit_payments, :id_number
    add_index :limit_payments, :status
  end
end
