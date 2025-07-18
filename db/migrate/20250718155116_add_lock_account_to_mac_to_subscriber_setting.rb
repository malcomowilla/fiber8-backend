class AddLockAccountToMacToSubscriberSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_settings, :lock_account_to_mac, :boolean
  end
end
