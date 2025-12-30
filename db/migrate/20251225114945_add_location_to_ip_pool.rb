class AddLocationToIpPool < ActiveRecord::Migration[7.2]
  def change
    add_column :ip_pools, :location, :string
  end
end
