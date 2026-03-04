class AddIndexToUsernameRadUserGroup < ActiveRecord::Migration[7.2]
  def change
    add_index :radusergroup, :username
  end
end
