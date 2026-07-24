class AddDeviceAndMetaToAdEvents < ActiveRecord::Migration[7.2]
  def change
     add_column :ad_events, :mac, :string
    add_index  :ad_events, [:ad_setting_id, :mac]
  end
end
