class AddAmountDisbursedToHotspotMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_mpesa_revenues, :amount_disbursed, :integer
  end
end
