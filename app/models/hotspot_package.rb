class HotspotPackage < ApplicationRecord
  acts_as_tenant(:account)

validates :name, presence: true, uniqueness: true

def valid_from_formatted
  format_for_mikrotik(object.valid_from)
end

def valid_until_formatted
  format_for_mikrotik(object.valid_until)
end

private

def format_for_mikrotik(datetime)
  return '' unless datetime.present?

  seconds_diff = (datetime - Time.current).to_i

  days = seconds_diff / (60 * 60 * 24)
  hours = (seconds_diff % (60 * 60 * 24)) / (60 * 60)
  minutes = (seconds_diff % (60 * 60)) / 60
  seconds = seconds_diff % 60

  "#{days} #{format('%02d', hours)}:#{format('%02d', minutes)}:#{format('%02d', seconds)}"
end
end
