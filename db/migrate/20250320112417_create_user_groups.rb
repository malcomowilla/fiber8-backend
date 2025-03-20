class CreateUserGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :user_groups do |t|
      t.string :name
      t.integer :account_id

      t.timestamps
    end
  end
end
