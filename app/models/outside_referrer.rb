class OutsideReferrer < ApplicationRecord
  has_secure_password

  has_many :referral_earnings, as: :referrer, dependent: :destroy
  has_many :referral_withdrawals, as: :referrer, dependent: :destroy
  has_many :referred_accounts, class_name: 'Account', foreign_key: :referred_by_outside_referrer_id

  before_validation :assign_referral_code, on: :create

  validates :name, :email, :phone_number, presence: true
  validates :email, uniqueness: true
  validates :phone_number, uniqueness: true
  validates :referral_code, uniqueness: true

  def available_balance
    referral_earnings.where(status: 'available', paid_out: false).sum(:amount)
  end

  def pending_balance
    referral_earnings.where(status: 'pending').sum(:amount)
  end

  def lifetime_earned
    referral_earnings.where.not(status: 'void').sum(:amount)
  end

  private

  def assign_referral_code
    return if referral_code.present?

    loop do
      code = "REF#{SecureRandom.alphanumeric(6).upcase}"
      next if OutsideReferrer.exists?(referral_code: code) || Account.exists?(referral_code: code)

      self.referral_code = code
      break
    end
  end
end