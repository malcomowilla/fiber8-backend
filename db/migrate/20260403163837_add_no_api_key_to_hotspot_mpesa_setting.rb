class AddNoApiKeyToHotspotMpesaSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_mpesa_settings, :no_api_keys, :boolean, default: false
  end
end
