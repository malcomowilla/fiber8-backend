# class CallCenterSetting < ApplicationRecord
#   acts_as_tenant(:account)

#   DAYS = %w[mon tue wed thu fri sat sun].freeze
#   TIME = /\A([01]\d|2[0-3]):[0-5]\d\z/

#   validates :open_from, :open_until, format: { with: TIME, message: "must be HH:MM" }
#   validates :hold_music_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
#   validate  :valid_timezone

#   def days
#     open_days.to_s.split(",") & DAYS
#   end

#   def open_now?(time = Time.current)
#     return true if always_open

#     t = time.in_time_zone(timezone)
#     return false unless days.include?(DAYS[(t.wday - 1) % 7])

#     mins = t.hour * 60 + t.min
#     to_minutes(open_from) <= mins && mins < to_minutes(open_until)
#   end

#   private

#   def to_minutes(str)
#     h, m = str.split(":").map(&:to_i)
#     h * 60 + m
#   end

#   def valid_timezone
#     errors.add(:timezone, "is invalid") unless ActiveSupport::TimeZone[timezone]
#   end
# end
class CallCenterSetting < ApplicationRecord
  acts_as_tenant(:account)

  DAYS = %w[mon tue wed thu fri sat sun].freeze
  TIME = /\A([01]\d|2[0-3]):[0-5]\d\z/

  before_validation :normalize_dids

  validates :open_from, :open_until, format: { with: TIME, message: "must be HH:MM" }
  validates :hold_music_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true
  validate  :valid_timezone
  validate  :dids_free

  def days
    open_days.to_s.split(",") & DAYS
  end

  def dids
    did_numbers.to_s.split(",").reject(&:blank?)
  end

  def open_now?(time = Time.current)
    return true if always_open

    t = time.in_time_zone(timezone)
    return false unless days.include?(DAYS[(t.wday - 1) % 7])

    mins = t.hour * 60 + t.min
    to_minutes(open_from) <= mins && mins < to_minutes(open_until)
  end

  private

  def to_minutes(str)
    h, m = str.split(":").map(&:to_i)
    h * 60 + m
  end

  def valid_timezone
    errors.add(:timezone, "is invalid") unless ActiveSupport::TimeZone[timezone]
  end

  # Digits only, comma separated.
  def normalize_dids
    self.did_numbers = did_numbers.to_s.split(/[\s,;]+/).map { |d| d.delete("^0-9") }.reject(&:blank?).uniq.join(",")
  end

  def dids_free
    dids.each do |d|
      taken = CallCenterSetting.unscoped.where.not(id: id).where("? = ANY(string_to_array(did_numbers, ','))", d).exists?
      errors.add(:did_numbers, "#{d} is already used by another account") if taken
    end
  end
end