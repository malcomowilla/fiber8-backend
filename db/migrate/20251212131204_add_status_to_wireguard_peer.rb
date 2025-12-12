class AddStatusToWireguardPeer < ActiveRecord::Migration[7.2]
  def change
    add_column :wireguard_peers, :status, :string
  end
end
