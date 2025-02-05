class AddStartAndEndIpToIpPools < ActiveRecord::Migration[7.1]
  def change
    add_column :ip_pools, :start_ip, :string
    add_column :ip_pools, :end_ip, :string
  end
end
