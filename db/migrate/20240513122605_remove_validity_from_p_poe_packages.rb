class RemoveValidityFromPPoePackages < ActiveRecord::Migration[7.1]
  def change
    remove_column :p_poe_packages, :validity, :integer
  end
end
