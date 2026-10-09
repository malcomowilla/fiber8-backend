class PayheroChannel < ApplicationRecord
  acts_as_tenant(:account)

  CHANNEL_TYPES = %w[paybill till bank].freeze

  validates :channel_type, inclusion: { in: CHANNEL_TYPES }
  validates :short_code, :description, :payhero_channel_id, presence: true

  def self.receiving_for(account_id)
    where(account_id: account_id, is_active: true).order(is_default: :desc, created_at: :asc).first
  end
end