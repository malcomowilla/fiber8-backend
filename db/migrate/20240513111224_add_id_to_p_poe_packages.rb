class AddIdToPPoePackages < ActiveRecord::Migration[7.1]
  def change
    add_column :p_poe_packages, :id, :integer
  end
end
