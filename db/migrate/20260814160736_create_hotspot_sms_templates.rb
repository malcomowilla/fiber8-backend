class CreateHotspotSmsTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :hotspot_sms_templates do |t|
      # 'single_compact' | 'single_notification' | 'multi_compact' | 'multi_notification'
      # (kept as a plain string so new categories -- expiry_reminder, renewal_confirmation,
      # payment_shortfall, payment_received, welcome_message -- can be added later
      # without a schema change)
      t.string  :category, null: false
      t.string  :title, null: false
      t.text    :message, null: false, default: ''
      t.boolean :active, null: false, default: false
      t.bigint  :account_id, null: false

      t.timestamps
    end

    add_index :hotspot_sms_templates, [:account_id, :category], unique: true, name: 'index_hotspot_sms_templates_on_account_and_category'
  end
end
