class CreateSubscribers < ActiveRecord::Migration[7.1]
  def change
    create_table :subscribers do |t|
      t.string :name
      t.integer :phone_number
      t.string :ppoe_username
      t.string :ppoe_password
      t.string :email
      t.string :ppoe_package
      t.date :date_registered
      t.integer :ref_no

      t.timestamps
    end
  end
end
