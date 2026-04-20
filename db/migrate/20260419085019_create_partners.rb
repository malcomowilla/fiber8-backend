class CreatePartners < ActiveRecord::Migration[7.2]
  def change
    create_table :partners do |t|
      t.string :full_name
      t.string :partner_type
      t.string :status
      t.string :email
      t.string :phone
      t.string :city
      t.string :country
      t.string :notes
      t.string :commission_type
      t.integer :commission_rate
      t.integer :fixed_amount
      t.integer :minimum_payout
      t.string :payout_method
      t.string :payout_frequency
      t.string :mpesa_number
      t.string :mpesa_name
      t.string :bank_name
      t.string :account_number
      t.string :account_name
      t.integer :account_id

      t.timestamps
    end
  end
end
