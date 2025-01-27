class CreateNasRouters < ActiveRecord::Migration[7.1]
  def change
    create_table :nas_routers do |t|
      t.string :name
      t.string :ip_address
      t.string :username
      t.string :password
      t.integer :account_id

      t.timestamps
    end
  end
end
