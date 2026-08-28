# app/models/tenant_sms_wallet_transaction.rb — unchanged, just confirming shape
class TenantSmsWalletTransaction < ApplicationRecord
  acts_as_tenant(:account)
  belongs_to :account
  belongs_to :tenant_sms_wallet
end