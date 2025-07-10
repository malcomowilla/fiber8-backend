class AddSubscriberWelcomeMessageToSubscriberSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_settings, :subscriber_welcome_message, :boolean
  end
end
