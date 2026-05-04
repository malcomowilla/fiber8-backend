class AddAttributesToNasRouter < ActiveRecord::Migration[7.2]
  def change
    add_column :nas_routers, :api_username, :string
    add_column :nas_routers, :api_password, :string
    add_column :nas_routers, :router_id, :string
    add_column :nas_routers, :router_ip, :string
  end
end
