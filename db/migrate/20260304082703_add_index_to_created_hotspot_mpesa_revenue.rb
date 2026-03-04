class AddIndexToCreatedHotspotMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    add_index :hotspot_mpesa_revenues, :created_at
  end
end
