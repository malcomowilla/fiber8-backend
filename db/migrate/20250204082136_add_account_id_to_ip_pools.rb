class AddAccountIdToIpPools < ActiveRecord::Migration[7.1]
  def change
    add_column :ip_pools, :account_id, :integer
  end
end
