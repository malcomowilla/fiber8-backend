class AddWinBoxRelayPortToNasRouter < ActiveRecord::Migration[7.2]
  def change
    add_column :nas_routers, :winbox_relay_port, :integer
add_index :nas_routers, :winbox_relay_port, unique: true
  end
end
