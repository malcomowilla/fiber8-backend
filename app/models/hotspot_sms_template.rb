# # app/models/hotspot_sms_template.rb
# class HotspotSmsTemplate < ApplicationRecord
#   acts_as_tenant(:account)
#   # belongs_to :account

#   CATEGORIES = %w[
#     single_compact
#     single_notification
#     multi_compact
#     multi_notification
#     expiration
#   ].freeze

#   SINGLE_USER_VARIABLES = %w[
#     customer_phone plan_name voucher_code username password validity price company_name
#   ].freeze

#   MULTI_USER_VARIABLES = %w[
#     customer_phone plan_name voucher_count voucher_list validity price company_name
#   ].freeze

#   EXPIRATION_VARIABLES = %w[
#     customer_phone voucher_code plan_name company_name
#   ].freeze

#   validates :category, presence: true, inclusion: { in: CATEGORIES }
#   validates :title, presence: true
#   validates :message, presence: true
#   validates :category, uniqueness: { scope: :account_id }

#   def multi_user?
#     category.start_with?('multi')
#   end

#   def allowed_variables
#     return EXPIRATION_VARIABLES if category == 'expiration'
#     multi_user? ? MULTI_USER_VARIABLES : SINGLE_USER_VARIABLES
#   end

#   def render(data = {})
#     message.gsub(/\{(\w+)\}/) do
#       key = Regexp.last_match(1)
#       data.key?(key.to_sym) ? data[key.to_sym].to_s : "{#{key}}"
#     end
#   end

#   def self.format_voucher_list(vouchers)
#     vouchers.each_with_index.map do |v, i|
#       "#{i + 1}. Code: #{v[:code]} | User: #{v[:username]} | Pass: #{v[:password]}"
#     end.join("\n")
#   end

#   # NEW: picks whichever template in a group ("single"/"multi") is
#   # currently toggled active, most-recently-updated wins if two are
#   # somehow both active. Falls back to nil so callers can hardcode a
#   # last-resort message.
#   def self.active_for(account_id, group)
#     where(account_id: account_id, active: true)
#       .where("category LIKE ?", "#{group}_%")
#       .order(updated_at: :desc)
#       .first
#   end
# end
# 
# app/models/hotspot_sms_template.rb
class HotspotSmsTemplate < ApplicationRecord
  acts_as_tenant(:account)

  CATEGORIES = %w[
    single_compact
    single_notification
    multi_compact
    multi_notification
    expiration
    tv_plan_purchase
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

  TV_PLAN_VARIABLES = %w[
    customer_phone device_name plan_name price validity portal_url company_name
  ].freeze

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :title, presence: true
  validates :message, presence: true
  validates :category, uniqueness: { scope: :account_id }

  def multi_user?
    category.start_with?('multi')
  end

  def allowed_variables
    case category
    when 'expiration'       then EXPIRATION_VARIABLES
    when 'tv_plan_purchase' then TV_PLAN_VARIABLES
    else multi_user? ? MULTI_USER_VARIABLES : SINGLE_USER_VARIABLES
    end
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

  # `group` is either a prefix ("single"/"multi", matched via LIKE against
  # single_compact/single_notification/etc.) or an exact flat category
  # ("expiration", "tv_plan_purchase") that has no group siblings.
  # Without this branch, active_for("expiration") and
  # active_for("tv_plan_purchase") would build "expiration_%" / 
  # "tv_plan_purchase_%" and never match anything, since neither category
  # actually has an underscore-suffix variant.
  def self.active_for(account_id, group)
    scope = where(account_id: account_id, active: true)
    scope = if CATEGORIES.include?(group)
      scope.where(category: group)
    else
      scope.where("category LIKE ?", "#{group}_%")
    end
    scope.order(updated_at: :desc).first
  end
end