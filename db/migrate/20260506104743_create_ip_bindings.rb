class CreateIpBindings < ActiveRecord::Migration[7.2]
  def change
    create_table :ip_bindings do |t|
      t.string :router
      t.string :name
      t.string :package
      t.string :mac
      t.string :ip
      t.string :expiry
      t.string :device_type
      t.integer :account_id
      t.integer :router_id

      t.timestamps
    end
  end
end
