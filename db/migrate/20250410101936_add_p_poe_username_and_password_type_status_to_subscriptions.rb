class AddPPoeUsernameAndPasswordTypeStatusToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :pppoe_username, :string
    add_column :subscriptions, :pppoe_password, :string
    add_column :subscriptions, :type, :string
  end
end
