# app/models/client_support_ticket.rb
class ClientSupportTicket < ApplicationRecord
  acts_as_tenant(:account)
  belongs_to :account

  CATEGORIES = %w[system payment network other].freeze
  PRIORITIES = %w[low medium high urgent].freeze
  STATUSES   = %w[open in_progress resolved closed].freeze

  validates :subject, presence: true
  validates :description, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }

  before_save :set_resolved_at

  scope :open_tickets, -> { where(status: %w[open in_progress]) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def set_resolved_at
    if status_changed? && status == 'resolved' && resolved_at.blank?
      self.resolved_at = Time.current
    end
  end
end