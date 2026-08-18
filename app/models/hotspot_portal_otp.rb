class HotspotPortalOtp < ApplicationRecord
  acts_as_tenant(:account)

  CODE_LENGTH = 5
  EXPIRY = 5.minutes

  def self.issue!(account_id, phone)
    where(account_id: account_id, phone: phone).delete_all
    code = SecureRandom.random_number(10**CODE_LENGTH).to_s.rjust(CODE_LENGTH, '0')
    create!(
      account_id: account_id,
      phone: phone,
      code_digest: BCrypt::Password.create(code),
      expires_at: Time.current + EXPIRY
    )
    code
  end

  def self.verify!(account_id, phone, code)
    record = where(account_id: account_id, phone: phone).order(created_at: :desc).first
    return false unless record
    return false if record.expires_at < Time.current
    return false if record.attempts >= 5

    record.increment!(:attempts)
    ok = BCrypt::Password.new(record.code_digest) == code.to_s
    record.destroy! if ok
    ok
  end
end