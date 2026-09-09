class CreateReferralWithdrawals < ActiveRecord::Migration[7.2]
 def change
    create_table :referral_withdrawals do |t|
      t.string  :referrer_type, null: false
      t.bigint  :referrer_id, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string  :phone_number, null: false
      t.string  :status, default: 'pending', null: false
      t.string  :idempotency_key, null: false
      t.string  :error_message
      t.datetime :paid_out_at

      t.timestamps
    end

    add_index :referral_withdrawals, [:referrer_type, :referrer_id], name: 'index_referral_withdrawals_on_referrer'
    add_index :referral_withdrawals, :idempotency_key, unique: true
  end
end
