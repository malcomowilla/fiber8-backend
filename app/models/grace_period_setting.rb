class GracePeriodSetting < ApplicationRecord
  acts_as_tenant :account
  belongs_to :account

  UNITS = %w[minutes hours days].freeze

  validates :grace_period_value, numericality: { greater_than: 0 }
  validates :grace_period_unit, inclusion: { in: UNITS }

  def duration
    case grace_period_unit
    when 'minutes' then grace_period_value.minutes
    when 'hours'   then grace_period_value.hours
    when 'days'    then grace_period_value.days
    else 1.day
    end
  end
end