class AddLockedAccountToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :locked_account, :boolean, default: false
  end
end


