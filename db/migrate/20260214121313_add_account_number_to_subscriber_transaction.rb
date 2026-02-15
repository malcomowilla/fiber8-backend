class AddAccountNumberToSubscriberTransaction < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_transactions, :account_number, :string
    add_column :subscriber_transactions, :subscriber_id, :integer
  end
end
