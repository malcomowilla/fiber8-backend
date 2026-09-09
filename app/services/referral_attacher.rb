class ReferralAttacher
  def self.call(account, code)
    return if code.blank?
    return if account.referred_by_account_id.present? || account.referred_by_outside_referrer_id.present?

    if (referring_account = Account.find_by(referral_code: code))
      return if referring_account.id == account.id 
      account.update!(referred_by_account_id: referring_account.id)
    elsif (outside_referrer = OutsideReferrer.find_by(referral_code: code))
      account.update!(referred_by_outside_referrer_id: outside_referrer.id)
    end
  end
end