class AddAdSettingIdToAnalyticsEvents < ActiveRecord::Migration[7.2]
  def change
     add_column :analytics_events, :ad_setting_id, :bigint
    add_index :analytics_events, :ad_setting_id
  end
end
