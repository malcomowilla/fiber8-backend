class AddIndexToAccountIdHotspotSetting < ActiveRecord::Migration[7.2]
  def change
    add_index :hotspot_settings, :account_id
  end
end
