class AddValidityToPPoePackages < ActiveRecord::Migration[7.1]
  def change
    add_column :p_poe_packages, :validity, :integer
  end
end
