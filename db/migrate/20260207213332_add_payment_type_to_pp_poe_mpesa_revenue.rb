class AddPaymentTypeToPpPoeMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_mpesa_revenues, :payment_type, :string, default: "deposit"
  end
end
