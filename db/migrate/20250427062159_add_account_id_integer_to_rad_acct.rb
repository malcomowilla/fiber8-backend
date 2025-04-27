class AddAccountIdIntegerToRadAcct < ActiveRecord::Migration[7.2]
  def change
    add_column :rad_acct, :account_id, :integer
  end
end
