class EmailVerificationCode < ApplicationRecord
  TTL = 10.minutes
  MAX_ATTEMPTS = 5

  def self.digest(email, code)
    Digest::SHA256.hexdigest("#{email}:#{code}")
  end

  # One live code per email; also sweeps old expired rows
  def self.issue!(email, code)
    where('expires_at < ?', Time.current).delete_all
    where(email: email).delete_all
    create!(email: email, code_digest: digest(email, code), expires_at: TTL.from_now)
  end

  def self.latest_for(email)
    where(email: email).order(created_at: :desc).first
  end

  def expired?
    expires_at < Time.current
  end
end

