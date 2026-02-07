class AddTypeToPpPoeMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_mpesa_revenues, :type, :string, default: "deposit"
  end
end
