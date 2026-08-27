class CreatePlatformBulkSms < ActiveRecord::Migration[7.2]
  def change
    create_table :platform_bulk_sms_settings do |t|
      t.string  :api_key
      t.string  :partner_id
      t.string  :shortcode
      t.decimal :cost_price_per_sms, precision: 8, scale: 4, default: 0.30
      t.decimal :sell_price_per_sms, precision: 8, scale: 4, default: 0.60
      t.boolean :enabled, default: true
      t.timestamps
    end

    create_table :tenant_sms_wallets do |t|
      t.references :account, null: false, index: { unique: true }
      t.integer :balance, null: false, default: 0
      t.timestamps
    end

    create_table :tenant_sms_wallet_transactions do |t|
      t.references :account, null: false, index: true
      t.references :tenant_sms_wallet, null: false
      t.string  :transaction_type, null: false # 'purchase' | 'send' | 'refund'
      t.integer :quantity, null: false
      t.decimal :amount, precision: 10, scale: 2
      t.string  :reference
      t.string  :status, default: 'completed' # 'pending' | 'completed' | 'failed'
      t.string  :checkout_request_id
      t.timestamps
    end
    add_index :tenant_sms_wallet_transactions, :checkout_request_id
    add_index :tenant_sms_wallet_transactions, :reference
  end
end