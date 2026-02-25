class AddLoginByToHotspotMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_mpesa_revenues, :login_by, :string
  end
end
