# app/models/hotspot_sms_template.rb
class HotspotSmsTemplate < ApplicationRecord
  acts_as_tenant(:account)
  belongs_to :account

  CATEGORIES = %w[
    single_compact
    single_notification
    multi_compact
    multi_notification
    expiration
  ].freeze

  SINGLE_USER_VARIABLES = %w[
    customer_phone plan_name voucher_code username password validity price company_name
  ].freeze

  MULTI_USER_VARIABLES = %w[
    customer_phone plan_name voucher_count voucher_list validity price company_name
  ].freeze

  EXPIRATION_VARIABLES = %w[
    customer_phone voucher_code plan_name company_name
  ].freeze

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :title, presence: true
  validates :message, presence: true
  validates :category, uniqueness: { scope: :account_id }

  def multi_user?
    category.start_with?('multi')
  end

  def allowed_variables
    return EXPIRATION_VARIABLES if category == 'expiration'
    multi_user? ? MULTI_USER_VARIABLES : SINGLE_USER_VARIABLES
  end

  def render(data = {})
    message.gsub(/\{(\w+)\}/) do
      key = Regexp.last_match(1)
      data.key?(key.to_sym) ? data[key.to_sym].to_s : "{#{key}}"
    end
  end

  def self.format_voucher_list(vouchers)
    vouchers.each_with_index.map do |v, i|
      "#{i + 1}. Code: #{v[:code]} | User: #{v[:username]} | Pass: #{v[:password]}"
    end.join("\n")
  end

  # NEW: picks whichever template in a group ("single"/"multi") is
  # currently toggled active, most-recently-updated wins if two are
  # somehow both active. Falls back to nil so callers can hardcode a
  # last-resort message.
  def self.active_for(account_id, group)
    where(account_id: account_id, active: true)
      .where("category LIKE ?", "#{group}_%")
      .order(updated_at: :desc)
      .first
  end
end