class AddPpoeUsernameAndPassToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :ppoe_password, :string
    add_column :subscriptions, :ppoe_username, :string
  end
end
