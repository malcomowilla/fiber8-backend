class AddExpirationSmsSentAtToSubscription < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :expiration_sms_sent_at, :datetime
  end
end
