class FixSmsSettingsTenantScoping < ActiveRecord::Migration[7.2]
 def up
    execute "UPDATE sms_settings SET account_id = tenant_id WHERE account_id IS NULL AND tenant_id IS NOT NULL"
    add_index :sms_settings, [:account_id, :sms_provider], unique: true, name: 'index_sms_settings_on_account_and_provider'
  end

  def down
    remove_index :sms_settings, name: 'index_sms_settings_on_account_and_provider'
  end
end
