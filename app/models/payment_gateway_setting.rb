# app/models/payment_gateway_setting.rb
class PaymentGatewaySetting < ApplicationRecord
  belongs_to :account
  validates :use_case, inclusion: { in: %w[hotspot tv_plans] }
  validates :gateway,  inclusion: { in: %w[mpesa tuma paystack sasapay] }
  validates :gateway,  uniqueness: { scope: [:account_id, :use_case] }

  def self.active_gateway_for(account_id, use_case)
    find_by(account_id: account_id, use_case: use_case)&.gateway || 'mpesa'
  end
end