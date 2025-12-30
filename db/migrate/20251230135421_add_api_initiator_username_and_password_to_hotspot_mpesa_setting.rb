class AddApiInitiatorUsernameAndPasswordToHotspotMpesaSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_mpesa_settings, :api_initiator_password, :string
    add_column :hotspot_mpesa_settings, :api_initiator_username, :string
  end
end
