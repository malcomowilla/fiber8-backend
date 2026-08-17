class AddHotspotPortalSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :hotspot_customizations, :max_customer_bypass_devices, :integer, default: 1
    add_column :hotspot_customizations, :allow_device_self_service, :boolean, default: false
    # per-binding "admin unlocked a re-add because MAC/IP changed" flag
    add_column :ip_bindings, :replacement_allowed, :boolean, default: false
    add_column :ip_bindings, :account_number_source, :string # optional, for your own bookkeeping
  end
end
