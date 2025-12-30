class AddNasRouterToIpPool < ActiveRecord::Migration[7.2]
  def change
    add_column :ip_pools, :nas_router, :string
  end
end
