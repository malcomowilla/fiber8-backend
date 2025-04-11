class AddNasTotalIpAdressesNetMaskClientHostRangeToIpNetworks < ActiveRecord::Migration[7.2]
  def change
    add_column :ip_networks, :total_ip_addresses, :string
    add_column :ip_networks, :net_mask, :string
    add_column :ip_networks, :client_host_range, :string
  end
end
