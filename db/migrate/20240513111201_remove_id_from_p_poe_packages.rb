class RemoveIdFromPPoePackages < ActiveRecord::Migration[7.1]
  def change
    remove_column :p_poe_packages, :id, :string
  end
end
