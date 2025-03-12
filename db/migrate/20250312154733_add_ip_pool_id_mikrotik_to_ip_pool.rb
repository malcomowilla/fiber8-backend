class AddIpPoolIdMikrotikToIpPool < ActiveRecord::Migration[7.2]
  def change
    add_column :ip_pools, :ip_pool_id_mikrotik, :string
  end
end
