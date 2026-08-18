class AddTvPortalReplacementFields < ActiveRecord::Migration[7.2]
    def change
    # Per-tenant policy for TV-plan device *replacements* (not free "add device").
    # Reusing the hotspot_bypass_settings table your DeviceLimitSettings.jsx already reads.
    unless column_exists?(:hotspot_bypass_settings, :max_tv_plan_replacements)
      add_column :hotspot_bypass_settings, :max_tv_plan_replacements, :integer, default: 1, null: false
    end
    unless column_exists?(:hotspot_bypass_settings, :tv_plan_replacement_requires_unlock)
      add_column :hotspot_bypass_settings, :tv_plan_replacement_requires_unlock, :boolean, default: true, null: false
    end

    unless column_exists?(:ip_bindings, :replacement_allowed)
      add_column :ip_bindings, :replacement_allowed, :boolean, default: false, null: false
    end
    unless column_exists?(:ip_bindings, :replacement_count)
      add_column :ip_bindings, :replacement_count, :integer, default: 0, null: false
    end

    # Tag TV-plan mpesa revenue rows so admin can filter "how did this TV get paid"
    unless column_exists?(:hotspot_mpesa_revenues, :payment_type)
      add_column :hotspot_mpesa_revenues, :payment_type, :string, default: 'voucher', null: false
    end
    unless column_exists?(:hotspot_mpesa_revenues, :tv_plan_id)
      add_column :hotspot_mpesa_revenues, :tv_plan_id, :bigint
    end
    unless column_exists?(:hotspot_mpesa_revenues, :device_name)
      add_column :hotspot_mpesa_revenues, :device_name, :string
    end


    create_table :hotspot_portal_otps do |t|
      t.bigint  :account_id, null: false
      t.string  :phone, null: false
      t.string  :code_digest, null: false
      t.datetime :expires_at, null: false
      t.integer :attempts, default: 0, null: false
      t.timestamps
    end
    add_index :hotspot_portal_otps, [:account_id, :phone]
  end
end
