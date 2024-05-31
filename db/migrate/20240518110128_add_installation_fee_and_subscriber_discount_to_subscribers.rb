class AddInstallationFeeAndSubscriberDiscountToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :installation_fee, :string
    add_column :subscribers, :subscriber_discount, :string
  end
end
