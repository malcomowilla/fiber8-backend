class LimitPayment < ApplicationRecord
  STATUSES = %w[pending paid failed].freeze

  # Source of truth for fees. The client never sends the amount.
  TIERS = {
    5000  => 99,
    7500  => 150,
    10000 => 240,
    12500 => 360,
    16000 => 450,
    21000 => 570,
    25500 => 670,
    30000 => 780,
    35000 => 910,
    40000 => 1050,
    45000 => 1200,
    50000 => 1400,
    60000 => 1600,
    70000 => 2000
  }.freeze

  validates :id_number, :phone, :new_limit, :amount, :external_reference, presence: true
  validates :external_reference, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  before_validation :set_reference, on: :create

  scope :pending, -> { where(status: 'pending') }

  def self.fee_for(limit)
    TIERS[limit.to_i]
  end

  def pending? = status == 'pending'
  def paid?    = status == 'paid'
  def failed?  = status == 'failed'

  def mark_paid!(receipt: nil, payload: nil)
    return if paid?

    update!(status: 'paid', mpesa_receipt: receipt, callback_payload: payload, paid_at: Time.current)
    # TODO: apply the limit boost here (call whatever raises the limit for id_number -> new_limit)
  end

  def mark_failed!(desc: nil, payload: nil)
    return if paid?

    update!(status: 'failed', result_desc: desc, callback_payload: payload)
  end

  private

  def set_reference
    self.external_reference ||= "LIMIT-#{SecureRandom.hex(6).upcase}"
  end
end