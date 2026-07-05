class AddTrackingCountersToAdSettings < ActiveRecord::Migration[7.2]
  def change
     add_column :ad_settings, :impressions_count, :integer, default: 0, null: false
    add_column :ad_settings, :clicks_count, :integer, default: 0, null: false
  end
end
