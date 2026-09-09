class AddReferralFieldsToAccounts < ActiveRecord::Migration[7.2]
 def change
    add_column :accounts, :referral_code, :string
    add_column :accounts, :referred_by_account_id, :bigint
    add_column :accounts, :referred_by_outside_referrer_id, :bigint
    add_column :accounts, :referral_qualified_at, :datetime

    add_index :accounts, :referral_code, unique: true
    add_index :accounts, :referred_by_account_id
    add_index :accounts, :referred_by_outside_referrer_id
  end
end
