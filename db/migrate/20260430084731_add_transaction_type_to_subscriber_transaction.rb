class AddTransactionTypeToSubscriberTransaction < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_transactions, :transaction_type, :string
  end
end
