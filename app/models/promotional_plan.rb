# app/models/promotional_plan.rb
class PromotionalPlan < ApplicationRecord
  acts_as_tenant :account

  belongs_to :hotspot_package
  belongs_to :account

  RECURRENCE_TYPES = %w[one_time daily_window].freeze
  DISCOUNT_TYPES    = %w[percentage fixed_amount].freeze

  validates :name, presence: true
  validates :start_date, :end_date, presence: true
  validates :recurrence_type, inclusion: { in: RECURRENCE_TYPES }
  validates :discount_type, inclusion: { in: DISCOUNT_TYPES }
  validates :discount_value, numericality: { greater_than: 0 }
  validates :discount_value, numericality: { less_than_or_equal_to: 100 }, if: -> { discount_type == 'percentage' }
  validates :description, length: { maximum: 500 }
  validate  :end_date_after_start_date
  validate  :daily_window_times_present

  scope :active_flagged, -> { where(active: true) }

  scope :within_date_range, -> {
    now = Time.current
    where('start_date <= ? AND end_date >= ?', now, now)
  }

  scope :ordered_for_display, -> { order(display_priority: :desc, created_at: :desc) }

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "must be after the start date") if end_date <= start_date
  end

  def daily_window_times_present
    return unless recurrence_type == 'daily_window'

    errors.add(:daily_start_time, "is required for a daily window promotion") if daily_start_time.blank?
    errors.add(:daily_end_time, "is required for a daily window promotion") if daily_end_time.blank?
  end

  # Is this promotion currently redeemable right now (schedule + recurrence + stock)?
  def currently_active?
    return false unless active
    now = Time.current
    return false unless (start_date..end_date).cover?(now)
    return false if sold_out?

    if recurrence_type == 'daily_window'
      within_daily_window?(now)
    else
      true
    end
  end

  def within_daily_window?(time = Time.current)
    return true if daily_start_time.blank? || daily_end_time.blank?

    current = time.strftime('%H:%M:%S')
    start_t = daily_start_time.strftime('%H:%M:%S')
    end_t   = daily_end_time.strftime('%H:%M:%S')

    if start_t <= end_t
      current >= start_t && current <= end_t
    else
      # window crosses midnight, e.g. 22:00 - 02:00
      current >= start_t || current <= end_t
    end
  end

  def sold_out?
    max_redemptions.present? && current_redemptions >= max_redemptions
  end

  def remaining_stock
    return nil if max_redemptions.blank?

    [max_redemptions - current_redemptions, 0].max
  end

  def original_price
    hotspot_package&.price.to_f
  end

  def discount_amount
    if discount_type == 'percentage'
      (original_price * (discount_value.to_f / 100.0)).round(2)
    else
      [discount_value.to_f, original_price].min.round(2)
    end
  end

  def promotional_price
    [(original_price - discount_amount), 0].max.round(2)
  end

  def savings_percent
    return 0 if original_price.zero?

    ((discount_amount / original_price) * 100).round
  end

  # Seconds remaining until this promotion (or today's daily window) closes
  def seconds_remaining(time = Time.current)
    if recurrence_type == 'daily_window' && daily_end_time.present?
      end_today = time.change(hour: daily_end_time.hour, min: daily_end_time.min, sec: daily_end_time.sec)
      end_today += 1.day if end_today < time && daily_start_time && daily_start_time > daily_end_time
      [(end_today - time).to_i, 0].max
    else
      [(end_date - time).to_i, 0].max
    end
  end

  def as_public_json
    {
      id: id,
      name: name,
      badge_text: badge_text,
      description: description,
      package_id: hotspot_package_id,
      package_name: hotspot_package&.name,
      original_price: original_price,
      promotional_price: promotional_price,
      discount_type: discount_type,
      discount_value: discount_value.to_f,
      savings_amount: discount_amount,
      savings_percent: savings_percent,
      recurrence_type: recurrence_type,
      end_date: end_date,
      seconds_remaining: seconds_remaining,
      show_countdown_timer: show_countdown_timer,
      show_stock_indicator: show_stock_indicator,
      max_redemptions: max_redemptions,
      remaining_stock: remaining_stock,
      display_priority: display_priority
    }
  end
end