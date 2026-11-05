class HotspotBlockedNumber < ApplicationRecord
  acts_as_tenant :account
  belongs_to :account

  validates :phone_number, presence: true, uniqueness: { scope: :account_id }
  validates :reason, length: { maximum: 255 }

  # "0712 345 678", "+254712345678", "712345678" -> "254712345678"
  # Returns nil if it isn't a valid Kenyan mobile number.
  def self.normalize(phone)
    digits = phone.to_s.gsub(/\D/, '')
    digits = digits.sub(/\A254/, '').sub(/\A0/, '')
    digits.match?(/\A[17]\d{8}\z/) ? "254#{digits}" : nil
  end

  # "254712345678" -> "0712345678"
  def self.display(phone)
    "0#{phone.to_s.last(9)}"
  end

  # True if the phone is blocked, or the device (MAC) previously bought
  # with a blocked number.
  def self.blocked?(account_id, phone: nil, mac: nil)
    blocked = where(account_id: account_id).pluck(:phone_number)
    return false if blocked.empty?

    normalized = normalize(phone)
    return true if normalized && blocked.include?(normalized)

    if mac.present?
      seen = TemporarySession
               .where(account_id: account_id)
               .where('UPPER(mac) = ?', mac.to_s.upcase)
               .limit(50)
               .pluck(:phone_number)
      return true if seen.any? { |p| (n = normalize(p)) && blocked.include?(n) }
    end

    false
  end
end