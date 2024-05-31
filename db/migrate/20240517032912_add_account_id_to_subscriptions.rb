class AddAccountIdToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :account_id, :integer
  end
end
