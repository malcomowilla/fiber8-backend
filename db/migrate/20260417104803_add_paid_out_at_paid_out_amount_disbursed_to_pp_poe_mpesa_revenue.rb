class AddPaidOutAtPaidOutAmountDisbursedToPpPoeMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
     add_column :pp_poe_mpesa_revenues, :paid_out_at, :datetime
     add_column :pp_poe_mpesa_revenues, :paid_out, :boolean, default: false
     add_column :pp_poe_mpesa_revenues, :amount_disbursed, :integer 
  end
end
