class CollectorTransaction < ApplicationRecord
  acts_as_tenant(:account, require_tenant: true)

  PACK_PRICE = BigDecimal("200") # KSh per bag pack (same number as frontend config/constants.js)
  FEE_RATE   = BigDecimal("0.03") # platform fee 3%

  class NothingToWithdraw < StandardError; end

  belongs_to :collector_customer, optional: true

  validates :kind, inclusion: { in: %w[payment withdrawal] }
  validates :label, presence: true

  def self.balance
    where(kind: "payment").sum(:net) - where(kind: "withdrawal").sum(:net)
  end

  # Customer paid for a pack. Locks the account row so two requests can't clash.
  def self.record_payment(customer)
    ActsAsTenant.current_tenant.with_lock do
      fee = (PACK_PRICE * FEE_RATE).round(2)
      create!(collector_customer: customer, kind: "payment", label: "#{customer.name} · Unit #{customer.unit}",
              gross: PACK_PRICE, fee: fee, net: PACK_PRICE - fee)
      customer.increment!(:packs_paid)
    end
  end

  # Records the withdrawal. Put the real M-Pesa payout call here later.
  def self.withdraw_all
    ActsAsTenant.current_tenant.with_lock do
      amount = balance
      raise NothingToWithdraw if amount <= 0

      create!(kind: "withdrawal", label: "Withdrawal to M-Pesa", net: amount)
    end
  end

  def as_row
    {
      id: id, type: kind, label: label,
      gross: gross.to_f, fee: fee.to_f, net: net.to_f,
      time: created_at.in_time_zone("Nairobi").strftime("%d %b, %H:%M")
    }
  end
end