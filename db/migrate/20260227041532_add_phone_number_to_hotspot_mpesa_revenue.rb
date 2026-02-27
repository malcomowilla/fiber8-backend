class AddPhoneNumberToHotspotMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_mpesa_revenues, :phone_number, :string
  end
end
