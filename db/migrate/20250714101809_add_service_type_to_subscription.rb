class AddServiceTypeToSubscription < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :service_type, :string
  end
end
