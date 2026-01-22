class AddCustomerNameToPpPoeMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_mpesa_revenues, :customer_name, :string
  end
end
