class AddPriceToPpPoePlan < ActiveRecord::Migration[7.2]
  def change
    add_column :pp_poe_plans, :price, :string
  end
end
