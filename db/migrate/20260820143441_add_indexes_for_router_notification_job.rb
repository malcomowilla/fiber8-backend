class AddIndexesForRouterNotificationJob < ActiveRecord::Migration[7.2]
  


  def change
    
    # ── NasRouter ──────────────────────────────────────────────
    # Used in: NasRouter.where(account_id: tenant.id)
    add_index :nas_routers, :account_id unless index_exists?(:nas_routers, :account_id)
    
    # Used in: nas_router.last_status != new_status
    add_index :nas_routers, :last_status unless index_exists?(:nas_routers, :last_status)
    
    # Used in: nas_router.last_status_changed_at
    add_index :nas_routers, :last_status_changed_at unless index_exists?(:nas_routers, :last_status_changed_at)
    
    # Used in: nas_router.last_notification_sent_at
    add_index :nas_routers, :last_notification_sent_at unless index_exists?(:nas_routers, :last_notification_sent_at)

    # Composite — most common query pattern
    add_index :nas_routers, [:account_id, :last_status] unless index_exists?(:nas_routers, [:account_id, :last_status])

    # ── NasSetting ─────────────────────────────────────────────
    # Used in: tenant&.nas_setting&.notification_when_unreachable
    add_index :nas_settings, :account_id unless index_exists?(:nas_settings, :account_id)
    add_index :nas_settings, :notification_when_unreachable unless index_exists?(:nas_settings, :notification_when_unreachable)

    # ── SmsSetting / SmsProviderSetting ────────────────────────
    # Used in: tenant.sms_provider_setting&.sms_provider
    add_index :sms_provider_settings, :account_id unless index_exists?(:sms_provider_settings, :account_id)
    add_index :sms_settings, :account_id unless index_exists?(:sms_settings, :account_id)
    add_index :sms_settings, :sms_provider unless index_exists?(:sms_settings, :sms_provider)
      
    # ── Account ────────────────────────────────────────────────
    # Used in: Account.find_each (already has PK index)
    # Used in: Account.find_by(subdomain:)
    add_index :accounts, :subdomain unless index_exists?(:accounts, :subdomain)

    # ── SystemAdminSm ──────────────────────────────────────────
    # Used in: SystemAdminSm.create! with account_id
    add_index :system_admin_sms, :account_id unless index_exists?(:system_admin_sms, :account_id)
    add_index :system_admin_sms, :created_at unless index_exists?(:system_admin_sms, :created_at)

  end

end
