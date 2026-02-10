class AddDescriptionToPpPoePlan < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_plans, :description, :string, default: "25 ksh per customer"
  end
end
