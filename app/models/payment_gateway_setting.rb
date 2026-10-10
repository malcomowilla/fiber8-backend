class PaymentGatewaySetting < ApplicationRecord
  USE_CASES = %w[hotspot tv_plans].freeze
  GATEWAYS  = %w[mpesa payhero tuma paystack sasapay].freeze

  belongs_to :account

  validates :use_case, inclusion: { in: USE_CASES }
  validates :gateway,  inclusion: { in: GATEWAYS }
  validates :use_case, uniqueness: { scope: :account_id }

  def self.active_gateway_for(account_id, use_case)
    find_by(account_id: account_id, use_case: use_case)&.gateway || 'mpesa'
  end
end