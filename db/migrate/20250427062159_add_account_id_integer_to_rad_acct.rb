class AddAccountIdIntegerToRadAcct < ActiveRecord::Migration[7.2]
  def change
    add_column :radacct, :account_id, :integer
  end
end
