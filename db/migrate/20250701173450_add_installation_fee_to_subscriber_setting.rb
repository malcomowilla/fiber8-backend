class AddInstallationFeeToSubscriberSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :subscriber_settings, :installation_fee, :string
  end
end
