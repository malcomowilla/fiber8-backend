class AddDhcpMacDhcpNameDhcpAdresingTypeDhcpConnectionStatusDhcpUptimeDhcpIpDhcpSubnetMaskDhcpGatewayDhcpDnsServersDhcpLastConectionErrorDhcpMaxMtuSizeDhcpNatEnabledDhcpVlanIdToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :dhcp_name, :string
    add_column :onus, :dhcp_addressing_type, :string
    add_column :onus, :dhcp_connection_status, :string
    add_column :onus, :dhcp_uptime, :string
    add_column :onus, :dhcp_ip, :string
    add_column :onus, :dhcp_subnet_mask, :string
    add_column :onus, :dhcp_gateway, :string
    add_column :onus, :dhcp_dns_servers, :string
    add_column :onus, :dhcp_last_connection_error, :string
    add_column :onus, :dhcp_max_mtu_size, :string
    add_column :onus, :dhcp_nat_enabled, :string
    add_column :onus, :dhcp_vlan_id, :string
    add_column :onus, :dhcp_mac_address, :string
  end
end
