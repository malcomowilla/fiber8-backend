class AddIsWalletAdminToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :wallet_admin, :boolean, default: false
  end
end
