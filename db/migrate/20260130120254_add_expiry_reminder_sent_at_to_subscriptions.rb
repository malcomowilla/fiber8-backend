class AddExpiryReminderSentAtToSubscriptions < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriptions, :expiry_reminder_sent_at, :datetime
  end
end
