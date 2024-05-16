class AddNasRouterIdToPPoePackages < ActiveRecord::Migration[7.1]
  def change
    add_column :p_poe_packages, :nas_router_id, :integer
  end
end
