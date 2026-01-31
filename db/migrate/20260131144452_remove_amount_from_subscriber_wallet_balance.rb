class RemoveAmountFromSubscriberWalletBalance < ActiveRecord::Migration[7.2]
  def change
    remove_column :subscriber_wallet_balances, :amount, :string
  end
end
