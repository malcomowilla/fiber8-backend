class AddAccountIdToWireguardPeer < ActiveRecord::Migration[7.2]
  def change
    add_column :wireguard_peers, :account_id, :integer
  end
end
