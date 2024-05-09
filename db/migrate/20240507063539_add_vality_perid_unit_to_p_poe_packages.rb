class AddValityPeridUnitToPPoePackages < ActiveRecord::Migration[7.1]
  def change
    add_column :p_poe_packages, :validity_period_units, :string
  end
end
