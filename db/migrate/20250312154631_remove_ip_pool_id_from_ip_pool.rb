class RemoveIpPoolIdFromIpPool < ActiveRecord::Migration[7.2]
  def change
    remove_column :ip_pools, :ip_pool_id, :string
  end
end
