class AddIndexToUsernameRadReply < ActiveRecord::Migration[7.2]
  def change
    add_index :radreply, :username
  end
end
