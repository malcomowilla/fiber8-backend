class CreateTechnicians < ActiveRecord::Migration[7.2]
  def change
    create_table :technicians do |t|
      t.string :email
      t.string :username
      t.string :phone_number
      t.string :password_digest
      t.integer :account_id

      t.timestamps
    end
  end
end
