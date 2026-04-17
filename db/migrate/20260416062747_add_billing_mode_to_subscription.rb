class AddBillingModeToSubscription < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :billing_mode, :string
  end
end
