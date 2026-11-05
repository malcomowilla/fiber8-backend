class PaymentGatewaySetting < ApplicationRecord
  USE_CASES = %w[hotspot tv_plans].freeze
  GATEWAYS  = %w[mpesa payhero tuma paystack sasapay kcb_buni].freeze

  # Gateways that can only be used for a subset of use cases.
  HOTSPOT_ONLY = %w[kcb_buni].freeze

  belongs_to :account

  validates :use_case, inclusion: { in: USE_CASES }
  validates :gateway,  inclusion: { in: GATEWAYS }
  validates :use_case, uniqueness: { scope: :account_id }
  validate  :hotspot_only_gateways_not_on_tv_plans

  def self.active_gateway_for(account_id, use_case)
    find_by(account_id: account_id, use_case: use_case)&.gateway || 'mpesa'
  end

  private

  def hotspot_only_gateways_not_on_tv_plans
    if use_case == 'tv_plans' && HOTSPOT_ONLY.include?(gateway)
      errors.add(:gateway, 'cannot be used for TV plans')
    end
  end
end