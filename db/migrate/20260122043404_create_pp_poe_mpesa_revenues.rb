class CreatePpPoeMpesaRevenues < ActiveRecord::Migration[7.2]
  def change
    create_table :pp_poe_mpesa_revenues do |t|
      t.string :payment_method
      t.string :amount
      t.string :reference
      t.datetime :time_paid
      t.integer :account_id
      t.string :account_number

      t.timestamps
    end
  end
end
