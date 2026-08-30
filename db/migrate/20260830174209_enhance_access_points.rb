class EnhanceAccessPoints < ActiveRecord::Migration[7.2]
  def change
    # Add new columns to access_points table
    add_column :access_points, :model, :string unless column_exists?(:access_points, :model)
    add_column :access_points, :brand, :string unless column_exists?(:access_points, :brand)
    add_column :access_points, :static_ip, :string unless column_exists?(:access_points, :static_ip)
    add_column :access_points, :mac_address, :string unless column_exists?(:access_points, :mac_address)
    add_column :access_points, :location, :string unless column_exists?(:access_points, :location)
    add_column :access_points, :notes, :text unless column_exists?(:access_points, :notes)
    add_column :access_points, :nas_router_id, :bigint unless column_exists?(:access_points, :nas_router_id)
    add_column :access_points, :hotspot_binding_done, :boolean, default: false unless column_exists?(:access_points, :hotspot_binding_done)
    add_column :access_points, :snmp_enabled, :boolean, default: false unless column_exists?(:access_points, :snmp_enabled)
    add_column :access_points, :snmp_community, :string, default: 'public' unless column_exists?(:access_points, :snmp_community)
    add_column :access_points, :snmp_version, :string, default: '2c' unless column_exists?(:access_points, :snmp_version)
    add_column :access_points, :uptime, :string unless column_exists?(:access_points, :uptime)
    add_column :access_points, :signal_strength, :integer unless column_exists?(:access_points, :signal_strength)
    add_column :access_points, :connected_clients, :integer, default: 0 unless column_exists?(:access_points, :connected_clients)
    add_column :access_points, :last_seen_at, :datetime unless column_exists?(:access_points, :last_seen_at)
    add_column :access_points, :firmware_version, :string unless column_exists?(:access_points, :firmware_version)
    add_column :access_points, :ping_latency_ms, :float unless column_exists?(:access_points, :ping_latency_ms)
    add_column :access_points, :setup_status, :string, default: 'pending' unless column_exists?(:access_points, :setup_status)
    # setup_status: pending, ip_assigned, binding_created, bypassed, verified

    # Indexes
    add_index :access_points, :account_id unless index_exists?(:access_points, :account_id)
    add_index :access_points, :reachable unless index_exists?(:access_points, :reachable)
    add_index :access_points, :nas_router_id unless index_exists?(:access_points, :nas_router_id)
    add_index :access_points, :setup_status unless index_exists?(:access_points, :setup_status)
  end
end
