class AddAmountToSubscriberWalletBalance < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_wallet_balances, :amount, :string
  end
end
