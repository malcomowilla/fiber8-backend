class AddWalletPinToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :wallet_pin, :string
  end
end
