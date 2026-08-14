class CreateNetworkConnection < ActiveRecord::Migration[7.2]
  def change
    unless table_exists?(:network_connections)
      create_table :network_connections do |t|
        t.timestamps
      end
    end

    add_reference :network_connections, :account, foreign_key: true, index: true unless column_exists?(:network_connections, :account_id)

    # Polymorphic source: add whichever half is actually missing, rather
    # than guarding add_reference (which inserts source_id + source_type
    # together) as a single unit. Your table already had a bare source_id
    # from an earlier non-polymorphic belongs_to :source, which is why the
    # combined guard blew up -- it only checked source_type and then tried
    # to add source_id again.
    add_column :network_connections, :source_id, :bigint unless column_exists?(:network_connections, :source_id)
    add_column :network_connections, :source_type, :string unless column_exists?(:network_connections, :source_type)
    unless index_exists?(:network_connections, %i[source_type source_id], name: 'index_network_connections_on_source')
      add_index :network_connections, %i[source_type source_id], name: 'index_network_connections_on_source'
    end

    add_column :network_connections, :target_id, :bigint unless column_exists?(:network_connections, :target_id)
    add_column :network_connections, :target_type, :string unless column_exists?(:network_connections, :target_type)
    unless index_exists?(:network_connections, %i[target_type target_id], name: 'index_network_connections_on_target')
      add_index :network_connections, %i[target_type target_id], name: 'index_network_connections_on_target'
    end

    add_column :network_connections, :category, :string unless column_exists?(:network_connections, :category) # adss | drop | ether | wifi
    add_column :network_connections, :cable_type, :string unless column_exists?(:network_connections, :cable_type) # e.g. "ADSS 24 Core"
    add_column :network_connections, :label, :string unless column_exists?(:network_connections, :label)
    add_column :network_connections, :bandwidth_mbps, :integer unless column_exists?(:network_connections, :bandwidth_mbps)
    add_column :network_connections, :distance_m, :integer unless column_exists?(:network_connections, :distance_m)
    add_column :network_connections, :status, :string, default: 'unknown' unless column_exists?(:network_connections, :status)

    # Optional custom polyline path (array of [lat, lng] pairs) -- falls back
    # to a straight line between source/target on the frontend if nil.
    add_column :network_connections, :path, :jsonb unless column_exists?(:network_connections, :path)

    add_index :network_connections, :account_id unless index_exists?(:network_connections, :account_id)
  end
end
