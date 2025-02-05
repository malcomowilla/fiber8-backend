class AddDescriptionToIpPools < ActiveRecord::Migration[7.1]
  def change
    add_column :ip_pools, :description, :string
  end
end
