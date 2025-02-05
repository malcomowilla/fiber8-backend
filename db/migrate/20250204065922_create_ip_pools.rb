class CreateIpPools < ActiveRecord::Migration[7.1]
  def change
    create_table :ip_pools do |t|
      t.string :ip_range
      t.string :pool_name

      t.timestamps
    end
  end
end
