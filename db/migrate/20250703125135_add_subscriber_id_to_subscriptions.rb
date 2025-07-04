class AddSubscriberIdToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :subscriber_id, :integer
  end
end
