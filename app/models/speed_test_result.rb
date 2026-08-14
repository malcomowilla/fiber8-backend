class SpeedTestResult < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :subscriber
  belongs_to :nas_router, optional: true

  validates :download_mbps, :upload_mbps, :tested_at, presence: true

  STATUS_THRESHOLDS = { critical: 0.5, warning: 0.7 }.freeze

  def self.classify(percent_of_plan)
    return 'healthy' if percent_of_plan.nil?
    return 'critical' if percent_of_plan < STATUS_THRESHOLDS[:critical]
    return 'warning'  if percent_of_plan < STATUS_THRESHOLDS[:warning]
    'healthy'
  end
end