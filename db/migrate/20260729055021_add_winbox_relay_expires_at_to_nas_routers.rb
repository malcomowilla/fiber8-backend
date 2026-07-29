class AddWinboxRelayExpiresAtToNasRouters < ActiveRecord::Migration[7.2]
  def change
    add_column :nas_routers, :winbox_relay_expires_at, :datetime
  end
end
