class AddTxAndRxToPPoePackages < ActiveRecord::Migration[7.1]
  def change
    add_column :p_poe_packages, :tx_rate_limit, :string
    add_column :p_poe_packages, :rx_rate_limit, :string
  end
end
