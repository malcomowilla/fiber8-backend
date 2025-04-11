class AddNetworkNameToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :network_name, :string
  end
end
