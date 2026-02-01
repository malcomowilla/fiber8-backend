class AddNameToHotspotMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_mpesa_revenues, :name, :string
  end
end
