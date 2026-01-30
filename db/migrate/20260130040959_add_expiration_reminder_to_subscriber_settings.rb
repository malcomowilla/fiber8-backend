class AddExpirationReminderToSubscriberSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_settings, :expiration_reminder, :boolean, default: false
    add_column :subscriber_settings, :expiration_reminder_minutes, :string
    add_column :subscriber_settings, :expiration_reminder_hours, :string
    add_column :subscriber_settings, :expiration_reminder_days, :string
  end
end

