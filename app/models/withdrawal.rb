class Withdrawal < ApplicationRecord
  acts_as_tenant(:account)
  # belongs_to :account

  validates :wallet_type, inclusion: { in: %w[hotspot pppoe] }
  validates :amount, numericality: { greater_than: 0 }
  validates :phone_number, presence: true
  validates :status, inclusion: { in: %w[pending completed failed] }
end