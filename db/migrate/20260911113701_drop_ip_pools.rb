class DropIpPools < ActiveRecord::Migration[7.2]
  def change
    drop_table :ip_pools
  end
end
