class CreateWireguardPeers < ActiveRecord::Migration[7.2]
  def change
    create_table :wireguard_peers do |t|
      t.string :public_key
      t.string :allowed_ips
      t.integer :persistent_keepalive

      t.timestamps
    end
  end
end
