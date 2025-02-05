class AddIpPoolIdToIpPools < ActiveRecord::Migration[7.1]
  def change
    add_column :ip_pools, :ip_pool_id, :string
  end
end
