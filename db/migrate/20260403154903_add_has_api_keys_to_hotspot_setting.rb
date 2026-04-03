class AddHasApiKeysToHotspotSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_settings, :has_api_key, :boolean
  end
end

