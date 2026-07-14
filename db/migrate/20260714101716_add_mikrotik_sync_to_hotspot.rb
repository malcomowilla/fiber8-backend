class AddMikrotikSyncToHotspot < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_vouchers, :sync_status, :string, default: 'not_synced' # not_synced | synced | failed
    add_column :hotspot_vouchers, :synced_at, :datetime
    add_column :hotspot_vouchers, :sync_error, :string

    add_column :hotspot_packages, :sync_status, :string, default: 'not_synced'
    add_column :hotspot_packages, :synced_at, :datetime
    add_column :hotspot_packages, :sync_error, :string
  end
end
