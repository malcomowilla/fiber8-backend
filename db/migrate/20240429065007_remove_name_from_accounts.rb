class RemoveNameFromAccounts < ActiveRecord::Migration[7.1]
  def change
    remove_column :accounts, :name, :string
  end
end
