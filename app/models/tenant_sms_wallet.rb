class TenantSmsWallet < ApplicationRecord
  acts_as_tenant(:account)
  belongs_to :account
  has_many :transactions, class_name: 'TenantSmsWalletTransaction'

  def self.for_current_tenant
    find_or_create_by!(account_id: ActsAsTenant.current_tenant.id)
  end

  def credit!(quantity, reference:, amount:, checkout_request_id: nil)
    with_lock do
      increment!(:balance, quantity)
      transactions.create!(
        account_id: account_id, transaction_type: 'purchase',
        quantity: quantity, amount: amount, reference: reference,
        checkout_request_id: checkout_request_id, status: 'completed'
      )
    end
  end

  def debit!(quantity, reference: nil)
    with_lock do
      raise 'Insufficient SMS balance' if balance < quantity
      decrement!(:balance, quantity)
      transactions.create!(
        account_id: account_id, transaction_type: 'send',
        quantity: quantity, reference: reference, status: 'completed'
      )
    end
  end
end