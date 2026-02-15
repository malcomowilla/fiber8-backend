class AddSubscriberIdToPpPoeMpesaRevenue < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_mpesa_revenues, :subscriber_id, :integer
  end
end
