class RemoveMikrotikIdFromPPoePackages < ActiveRecord::Migration[7.1]
  def change
    remove_column :p_poe_packages, :mikrotik_id, :integer
  end
end
