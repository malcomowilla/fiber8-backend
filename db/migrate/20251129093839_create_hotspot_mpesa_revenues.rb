class CreateHotspotMpesaRevenues < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_mpesa_revenues do |t|
      t.string :voucher
      t.string :payment_method
      t.string :amount
      t.string :reference
      t.string :time_paid
      t.integer :account_id

      t.timestamps
    end
  end
end
