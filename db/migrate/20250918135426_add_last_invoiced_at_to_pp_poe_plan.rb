class AddLastInvoicedAtToPpPoePlan < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_plans, :last_invoiced_at, :datetime
  end
end
