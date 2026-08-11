
class PaymentGatewayOtp < ApplicationRecord
  belongs_to :user
  belongs_to :account

  CODE_LENGTH        = 6
  EXPIRY_MINUTES      = 5
  MAX_ATTEMPTS        = 5
  RATE_LIMIT_WINDOW   = 10.minutes
  RATE_LIMIT_MAX      = 5

  validates :channel, inclusion: { in: %w[sms email] }

  def self.rate_limited?(user)
    where(user_id: user.id, created_at: RATE_LIMIT_WINDOW.ago..).count >= RATE_LIMIT_MAX
  end

  # Invalidates any prior unconsumed codes for the user, then issues a new one.
  # Returns [otp_record, raw_code] — raw_code is only ever held in memory,
  # never persisted (only its bcrypt digest is stored).
  def self.generate_for(user:, account:, channel:, request_ip:)
    where(user_id: user.id, consumed_at: nil)
      .update_all(consumed_at: Time.current, attempts: MAX_ATTEMPTS)

    raw_code = SecureRandom.random_number(10**CODE_LENGTH).to_s.rjust(CODE_LENGTH, '0')

    otp = create!(
      user: user,
      account: account,
      code_digest: BCrypt::Password.create(raw_code),
      channel: channel,
      expires_at: EXPIRY_MINUTES.minutes.from_now,
      request_ip: request_ip
    )

    [otp, raw_code]
  end

  def expired?
    Time.current > expires_at
  end

  def locked?
    attempts >= MAX_ATTEMPTS
  end

  # Returns a symbol describing the outcome: :ok, :expired, :locked,
  # :already_used, or :invalid
  def verify(code)
    return :expired if expired?
    return :locked if locked?
    return :already_used if consumed_at.present?

    if BCrypt::Password.new(code_digest) == code.to_s
      update!(consumed_at: Time.current)
      :ok
    else
      increment!(:attempts)
      locked? ? :locked : :invalid
    end
  end
end