class CreateOnus < ActiveRecord::Migration[7.2]
  def change
    create_table :onus do |t|
      t.string :serial_number
      t.string :oui
      t.string :product_class
      t.string :manufacturer
      t.string :onu_id
      t.string :status
      t.string :last_inform
      t.integer :account_id
      t.string :last_boot

      t.timestamps
    end
  end
end
