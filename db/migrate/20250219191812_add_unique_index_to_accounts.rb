class AddUniqueIndexToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_index :accounts, :subdomain, unique: true
  end
end
