class CreateEquipment < ActiveRecord::Migration[7.2]
  def change
    create_table :equipment do |t|
      t.string :user
      t.string :type
      t.string :name
      t.string :model
      t.string :serial_number
      t.string :price
      t.string :amount_paid
      t.string :account_number

      t.timestamps
    end
  end
end
