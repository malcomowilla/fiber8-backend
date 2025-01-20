class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    # create_table :users do |t|
       create_table :users, if_not_exists: true do |t|
      t.string :email
      t.string :password_digest

      t.timestamps
    end
  end
end



