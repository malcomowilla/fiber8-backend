class AddIndexToUserEmail < ActiveRecord::Migration[7.2]
  def change
    add_index :users, :email
  end
end



