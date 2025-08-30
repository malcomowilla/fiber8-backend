class AddLanIpInterfaceAddressLanIpInterfaceNetMaskDhcpServerEnableDhcpIpPoolMinAddrDhcpIpPoolMaxAddrDhcpSubnetMaskDhcpDefaultGatewayDhcpDnsServersLeaseTimeClientsDomainNameReservedIpAddressToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :lan_ip_interface_address, :string
    add_column :onus, :lan_ip_interface_net_mask, :string
    add_column :onus, :dhcp_server_enable, :boolean
    add_column :onus, :dhcp_ip_pool_min_addr, :string
    add_column :onus, :dhcp_ip_pool_max_addr, :string
    add_column :onus, :dhcp_server_subnet_mask, :string
    add_column :onus, :dhcp_server_default_gateway, :string
    add_column :onus, :dhcp_server_dns_servers, :string
    add_column :onus, :lease_time, :string
    add_column :onus, :clients_domain_name, :string
    add_column :onus, :reserved_ip_address, :string
  end
end
