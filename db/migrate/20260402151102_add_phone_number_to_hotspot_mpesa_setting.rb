class AddPhoneNumberToHotspotMpesaSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_mpesa_settings, :phone_number, :string
  end
end
