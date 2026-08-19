class CreateWithdrawals < ActiveRecord::Migration[7.2]
 def change
    create_table :withdrawals do |t|
      t.references :account, null: false, foreign_key: true
      t.string   :wallet_type,     null: false          # 'hotspot' | 'pppoe'
      t.decimal  :amount,          precision: 12, scale: 2, null: false
      t.string   :phone_number,    null: false
      t.string   :status,          null: false, default: 'pending' # pending | completed | failed
      t.string   :description
      t.string   :idempotency_key
      t.text     :error_message
      t.datetime :paid_out_at

      t.timestamps
    end

    add_index :withdrawals, [:account_id, :created_at]
    add_index :withdrawals, :idempotency_key
  end
end
