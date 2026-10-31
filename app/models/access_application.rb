class AccessApplication < ApplicationRecord
  RESERVED = %w[
    www admin api app mail smtp ftp system sys referals referral support billing
    cdn status dashboard owitech aitechs takapick test demo
  ].freeze
  STATUSES = %w[pending approved rejected].freeze

  before_validation :normalize

  validates :name, :company_name, :subdomain, :email, :phone_number, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subdomain, format: { with: /\A[a-z0-9]{3,30}\z/, message: 'must be 3-30 letters or numbers' }
  validates :terms_accepted_at, presence: { message: 'must be accepted' }
  validate  :subdomain_available, on: :create

  def self.slugify(text)
    text.to_s.downcase.gsub(/[^a-z0-9]/, '')[0, 30]
  end

  # taken = reserved, used by another live application, or an account that already has users
  def self.subdomain_taken?(sub, except_id: nil)
    return true if RESERVED.include?(sub)
    return true if where(subdomain: sub, status: %w[pending approved]).where.not(id: except_id).exists?
    acc = Account.find_by(subdomain: sub)
    acc.present? && User.unscoped.exists?(account_id: acc.id)
  end

  def pending?  = status == 'pending'

  private

  def normalize
    self.email = email.to_s.strip.downcase
    self.company_name = company_name.to_s.strip
    self.subdomain = self.class.slugify(company_name)
    self.referral_code = referral_code.to_s.strip.presence
  end

  def subdomain_available
    errors.add(:company_name, 'is already taken, try another name') if self.class.subdomain_taken?(subdomain)
  end
end