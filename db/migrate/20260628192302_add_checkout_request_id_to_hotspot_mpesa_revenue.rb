class AddCheckoutRequestIdToHotspotMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_mpesa_revenues, :checkout_request_id, :string
  end
end
