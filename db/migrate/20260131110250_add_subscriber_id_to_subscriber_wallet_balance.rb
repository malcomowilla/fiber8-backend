class AddSubscriberIdToSubscriberWalletBalance < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_wallet_balances, :subscriber_id, :integer
  end
end
