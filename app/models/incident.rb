class Incident < ApplicationRecord
  acts_as_tenant :account
  belongs_to :account

  TYPES    = %w[outage maintenance degradation].freeze
  STATUSES = %w[ongoing resolved].freeze
  SERVICES = %w[hotspot pppoe both].freeze

  validates :title, presence: true
  validates :incident_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :start_time, presence: true
  validates :service_type, inclusion: { in: SERVICES }

  def hotspot_affected?
    %w[hotspot both].include?(service_type)
  end
end