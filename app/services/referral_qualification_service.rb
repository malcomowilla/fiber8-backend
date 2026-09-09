class ReferralQualificationService
  REWARD_AMOUNT  = (ENV['REFERRAL_REWARD_AMOUNT'] || 300).to_f
  CLEARING_DAYS  = (ENV['REFERRAL_CLEARING_DAYS'] || 3).to_i

  def self.call(account)
    new(account).call
  end

  def initialize(account)
    @account = account
  end

  def call
    return if @account.nil?
    return if @account.referral_qualified_at.present? # only the FIRST payment counts

    referrer = @account.referred_by_account || @account.referred_by_outside_referrer
    return unless referrer

    ActiveRecord::Base.transaction do
      ReferralEarning.create!(
        referrer: referrer,
        referred_account: @account,
        amount: REWARD_AMOUNT,
        status: 'pending',
        reason: referrer.is_a?(Account) ? 'inside_admin_referral' : 'outside_referral',
        available_at: CLEARING_DAYS.days.from_now
      )
      @account.update!(referral_qualified_at: Time.current)
    end
  end
end