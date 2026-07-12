class CreateNetworkConnections < ActiveRecord::Migration[7.2]
  def change
    create_table :network_connections do |t|
      t.string :source_kind
      t.bigint :source_id
      t.string :target_kind
      t.bigint :target_id
      t.string :category
      t.string :cable_type
      t.string :label
      t.integer :bandwidth_mbps
      t.integer :distance_m
      t.string :status
      t.json :path
      t.integer :account_id

      t.timestamps
    end
  end
end
