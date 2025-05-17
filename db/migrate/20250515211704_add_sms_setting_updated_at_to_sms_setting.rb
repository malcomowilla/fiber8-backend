class AddSmsSettingUpdatedAtToSmsSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :sms_settings, :sms_setting_updated_at, :datetime
  end
end
