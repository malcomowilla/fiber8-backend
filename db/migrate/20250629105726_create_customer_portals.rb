class CreateCustomerPortals < ActiveRecord::Migration[7.2]
  def change
    create_table :customer_portals do |t|
      t.string :username
      t.string :password
      t.integer :account_id

      t.timestamps
    end
  end
end
