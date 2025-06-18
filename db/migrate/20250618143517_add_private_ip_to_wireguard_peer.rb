class AddPrivateIpToWireguardPeer < ActiveRecord::Migration[7.2]
  def change
    add_column :wireguard_peers, :private_ip, :string
  end
end
