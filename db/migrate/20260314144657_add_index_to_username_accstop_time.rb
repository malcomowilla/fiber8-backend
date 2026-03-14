class AddIndexToUsernameAccstopTime < ActiveRecord::Migration[7.2]
  def change
    add_index :radacct, :username
    add_index :radacct, :acctstoptime
  end
end
