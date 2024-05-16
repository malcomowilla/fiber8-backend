class AddMikrotikIdToPPoePackages < ActiveRecord::Migration[7.1]
  def change
    add_column :p_poe_packages, :mikrotik_id, :string
  end
end
