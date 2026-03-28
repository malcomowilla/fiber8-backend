class AddAddSettingsPropertiesToAdSetting < ActiveRecord::Migration[7.2]
  def change
     add_column :ad_settings, :ad_title, :string
     add_column :ad_settings, :ad_link, :string
      add_column :ad_settings, :position, :string, default: 'bottom-right'
      add_column :ad_settings, :ad_duration, :integer, default: 15
      add_column :ad_settings, :skip_after, :integer, default: 5
      add_column :ad_settings, :can_skip, :boolean, default: true
       add_column :ad_settings, :ad_enabled, :boolean, default: false
       add_column :ad_settings, :media_type, :string



  end
end
