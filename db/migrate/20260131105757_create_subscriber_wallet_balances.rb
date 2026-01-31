class CreateSubscriberWalletBalances < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriber_wallet_balances do |t|
      t.integer :amount
      t.integer :account_id

      t.timestamps
    end
  end
end
