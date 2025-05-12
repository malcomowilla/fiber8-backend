class AddPhoneNotificationToLicenseSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :license_settings, :phone_notification, :boolean
  end
end
