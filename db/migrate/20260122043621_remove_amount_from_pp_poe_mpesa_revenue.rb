class RemoveAmountFromPpPoeMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    remove_column :pp_poe_mpesa_revenues, :amount, :string
  end
end
