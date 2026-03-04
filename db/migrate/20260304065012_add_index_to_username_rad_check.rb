class AddIndexToUsernameRadCheck < ActiveRecord::Migration[7.2]
  def change
    add_index :radcheck, :username
  end
end
