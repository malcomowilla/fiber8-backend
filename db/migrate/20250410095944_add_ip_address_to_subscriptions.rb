class AddIpAddressToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :ip_address, :string
  end
end
