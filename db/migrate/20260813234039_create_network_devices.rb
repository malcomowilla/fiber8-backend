class CreateNetworkDevices < ActiveRecord::Migration[7.2]
  def change
    unless table_exists?(:network_devices)
      create_table :network_devices do |t|
        t.timestamps
      end
    end

    add_reference :network_devices, :account, foreign_key: true, index: true unless column_exists?(:network_devices, :account_id)
    add_reference :network_devices, :pop, foreign_key: true, index: true unless column_exists?(:network_devices, :pop_id)

    # IMPORTANT: named `device_type`, not `type` — a plain `type` column
    # triggers Rails Single Table Inheritance and will break this model
    # in surprising ways the first time a value doesn't match a class name.
    add_column :network_devices, :device_type, :string unless column_exists?(:network_devices, :device_type)

    add_column :network_devices, :name, :string unless column_exists?(:network_devices, :name)
    add_column :network_devices, :identifier, :string unless column_exists?(:network_devices, :identifier)
    add_column :network_devices, :lat, :float unless column_exists?(:network_devices, :lat)
    add_column :network_devices, :lng, :float unless column_exists?(:network_devices, :lng)
    add_column :network_devices, :address, :string unless column_exists?(:network_devices, :address)
    add_column :network_devices, :router_id, :bigint unless column_exists?(:network_devices, :router_id)
    add_column :network_devices, :status, :string, default: 'unknown' unless column_exists?(:network_devices, :status)
    add_column :network_devices, :description, :text unless column_exists?(:network_devices, :description)

    # 'manual' | 'kml_import' | 'mikrotik_sync' — lets you tell at a glance
    # which devices came from your Google Earth import vs hand-placed ones.
    add_column :network_devices, :source, :string, default: 'manual' unless column_exists?(:network_devices, :source)
    add_column :network_devices, :metadata, :jsonb, default: {} unless column_exists?(:network_devices, :metadata)

    add_index :network_devices, :account_id unless index_exists?(:network_devices, :account_id)
    add_index :network_devices, :router_id unless index_exists?(:network_devices, :router_id)
  end
end
