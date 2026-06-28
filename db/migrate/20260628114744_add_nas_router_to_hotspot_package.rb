class AddNasRouterToHotspotPackage < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_packages, :nas_router, :string
  end
end
