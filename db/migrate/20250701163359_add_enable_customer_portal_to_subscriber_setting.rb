class AddEnableCustomerPortalToSubscriberSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_settings, :enable_customer_portal, :boolean, default: false
  end
end
