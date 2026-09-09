class CreateReferralEarnings < ActiveRecord::Migration[7.2]
  def change
    create_table :referral_earnings do |t|
      t.string  :referrer_type, null: false
      t.bigint  :referrer_id, null: false
      t.bigint  :referred_account_id, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      # pending -> available -> processing -> paid_out (or void)
      t.string   :status, default: 'pending', null: false
      t.string   :reason
      t.boolean  :paid_out, default: false
      t.datetime :available_at
      t.datetime :paid_out_at

      t.timestamps
    end

    add_index :referral_earnings, [:referrer_type, :referrer_id], name: 'index_referral_earnings_on_referrer'
    add_index :referral_earnings, :referred_account_id
    add_index :referral_earnings, :status
  end
end
