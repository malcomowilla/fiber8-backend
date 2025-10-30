class AddPlanNameToInvoice < ActiveRecord::Migration[7.2]
  def change
    add_column :invoices, :plan_name, :string
  end
end
