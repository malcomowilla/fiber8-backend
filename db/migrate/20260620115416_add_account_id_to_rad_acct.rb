class AddAccountIdToRadAcct < ActiveRecord::Migration[7.2]
  def change
    add_column :rad_accts, :account_id, :integer
  end
end
