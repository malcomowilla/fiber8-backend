class AddAccountIdToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :account_id, :integer
  end
end
