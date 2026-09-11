class RebuildPppoePlans < ActiveRecord::Migration[7.2]
  def change
    change_table :packages do |t|
      t.string   :plan_type, default: 'standard', null: false
      t.string   :router_profile_name
      t.boolean  :public, default: true
      t.bigint   :fup_throttle_plan_id
      t.boolean  :synced, default: false
      t.datetime :last_synced_at
    end

    change_column :packages,
                  :fup_data_limit,
                  :integer,
                  using: 'fup_data_limit::integer'

    create_table :package_routers do |t|
      t.references :package, null: false, foreign_key: true
      t.references :nas_router, null: false, foreign_key: true
      t.references :ip_pool, null: false, foreign_key: true
      t.string   :mikrotik_ppp_profile_id
      t.boolean  :synced, default: false
      t.boolean  :is_default, default: false
      t.datetime :last_synced_at
      t.string   :sync_error
      t.timestamps
    end

    add_index :package_routers, [:package_id, :nas_router_id], unique: true
  end
end