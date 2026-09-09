class Account < ApplicationRecord
    has_many :users, dependent: :destroy
    has_many :hotspot_templates,  dependent: :destroy
    has_one :hotspot_customization,  dependent: :destroy
    has_many :ads, dependent: :destroy
    has_many :packages, dependent: :destroy
    has_many :nas_routers, dependent: :destroy
    has_many :zones, dependent: :destroy
    has_many :subscribers, dependent: :destroy
    has_one :sms_setting, dependent: :destroy
    has_many :subscriptions, dependent: :destroy    
    has_many :prefix_and_digits, dependent: :destroy
    has_one :sms_provider_setting, dependent: :destroy
    has_one :company_setting, dependent: :destroy
    has_many :support_tickets, dependent: :destroy
    has_one :email_setting, dependent: :destroy
    has_one :router_setting, dependent: :destroy
    has_one :subscriber_setting, dependent: :destroy
    has_one :ticket_setting, dependent: :destroy
    has_one :admin_setting, dependent: :destroy
    has_one :sms_template, dependent: :destroy
    has_one :hotspot_setting, dependent: :destroy
    has_many :ip_pools, dependent: :destroy
    has_one :pp_poe_plan, dependent: :destroy
    
    has_one :license_setting, dependent: :destroy
    has_one :hotspot_plan, dependent: :destroy
    has_one :hotspot_and_dial_plan, dependent: :destroy
    has_one :calendar_setting, dependent: :destroy
    # belongs_to :pp_poe_plan
    # belongs_to :hotspot_plan
    has_many :user_groups, dependent: :destroy
    has_one :hotspot_mpesa_setting, dependent: :destroy
    has_one :dial_up_mpesa_setting, dependent: :destroy
    has_one :company_id, dependent: :destroy
    has_many :invoices, dependent: :destroy
    # has_one :ad_setting
    has_many :ad_settings, dependent: :destroy
    has_one :ad, dependent: :destroy
    has_many :hotspot_vouchers, dependent: :destroy
    has_one :nas_setting, dependent: :destroy
    has_one :access_point_setting, dependent: :destroy
    has_many :ip_bindings, dependent: :destroy
    




    has_many :referral_earnings, as: :referrer, dependent: :destroy
has_many :referral_withdrawals, as: :referrer, dependent: :destroy
belongs_to :referred_by_account, class_name: 'Account', optional: true
belongs_to :referred_by_outside_referrer, class_name: 'OutsideReferrer', optional: true
has_many :accounts_referred, class_name: 'Account', foreign_key: :referred_by_account_id


before_validation :assign_referral_code, on: :create

def available_referral_balance
  referral_earnings.where(status: 'available', paid_out: false).sum(:amount)
end

def pending_referral_balance
  referral_earnings.where(status: 'pending').sum(:amount)
end


private

def assign_referral_code
  return if referral_code.present?

  loop do
    code = "ISP#{SecureRandom.alphanumeric(6).upcase}"
    next if Account.exists?(referral_code: code) || OutsideReferrer.exists?(referral_code: code)

    self.referral_code = code
    break
  end
end
    
end
