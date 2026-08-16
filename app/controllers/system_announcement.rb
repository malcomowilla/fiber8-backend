class SystemAnnouncement < ApplicationRecord
  # Global / not tenant-scoped — system admins broadcast to every tenant.

  TYPES     = %w[feature fix alert maintenance general].freeze
  PRIORITIES = %w[low medium high].freeze

  validates :title, presence: true
  validates :body, presence: true
  validates :announcement_type, inclusion: { in: TYPES }
  validates :priority, inclusion: { in: PRIORITIES }

  before_validation :set_published_at, on: :create

  scope :live, -> {
    now = Time.current
    where(active: true)
      .where('published_at <= ?', now)
      .where('expires_at IS NULL OR expires_at > ?', now)
  }

  scope :recent, -> { order(published_at: :desc) }

  private

  def set_published_at
    self.published_at ||= Time.current
  end
end