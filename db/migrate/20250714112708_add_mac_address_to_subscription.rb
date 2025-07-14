class AddMacAddressToSubscription < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :mac_address, :string
  end
end
