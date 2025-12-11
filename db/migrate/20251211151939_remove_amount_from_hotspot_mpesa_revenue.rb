class RemoveAmountFromHotspotMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    remove_column :hotspot_mpesa_revenues, :amount, :string
  end
end
