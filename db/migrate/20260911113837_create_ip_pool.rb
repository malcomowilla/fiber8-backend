class CreateIpPool < ActiveRecord::Migration[7.2]
  def change
    create_table :ip_pools do |t|
      t.string   :name,              null: false
      t.references :nas_router,      null: false, foreign_key: true
      t.references :account,         null: false, foreign_key: true
      t.string   :ip_range_start,    null: false
      t.string   :ip_range_end,      null: false
      t.string   :subnet_mask
      t.string   :gateway
      t.string   :primary_dns
      t.string   :secondary_dns
      t.text     :description
      t.string   :status,            default: 'active', null: false
      t.boolean  :synced,            default: false, null: false
      t.datetime :last_synced_at
      t.string   :mikrotik_pool_id
      t.integer  :used_ips,          default: 0, null: false

      t.timestamps
    end

    add_index :ip_pools, [:account_id, :name], unique: true
  end
end
