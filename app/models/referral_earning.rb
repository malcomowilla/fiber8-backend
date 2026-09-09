class ReferralEarning < ApplicationRecord
  belongs_to :referrer, polymorphic: true
  belongs_to :referred_account, class_name: 'Account'

  validates :amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending available processing paid_out void] }

  scope :available, -> { where(status: 'available', paid_out: false) }
end