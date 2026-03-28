class AddRewardTypeFreeMinutesSelectedPackageToAdSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :ad_settings, :reward_type, :string, default: 'specific'
    add_column :ad_settings, :free_minutes, :integer, default: 30
    add_column :ad_settings, :selected_package, :string
  end
end
