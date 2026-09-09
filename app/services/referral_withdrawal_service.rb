class ReferralWithdrawalService
  IDEMPOTENCY_TTL      = 5.minutes
  MIN_WITHDRAWAL_AMOUNT = (ENV['REFERRAL_MIN_WITHDRAWAL'] || 300).to_f

  def self.call(referrer:, phone_number:, idempotency_key:)
    new(referrer, phone_number, idempotency_key).call
  end

  def initialize(referrer, phone_number, idempotency_key)
    @referrer = referrer
    @phone_number = phone_number
    @idempotency_key = idempotency_key
  end

  def call
    return { success: false, error: 'Phone number is required' } if @phone_number.blank?
    return { success: false, error: 'Missing idempotency key' } if @idempotency_key.blank?

    cache_key = "referral_withdrawal_lock:#{@referrer.class.name}:#{@referrer.id}:#{@idempotency_key}"
    unless Rails.cache.write(cache_key, true, unless_exist: true, expires_in: IDEMPOTENCY_TTL)
      return { success: false, error: 'Duplicate withdrawal request already in progress' }
    end

    begin
      lock_result = lock_and_reserve_balance
      return lock_result unless lock_result[:success]

      withdrawal_log = lock_result[:withdrawal_log]
      amount = lock_result[:amount]

      if PlatformB2cService.disburse(@phone_number, amount)
        mark_earnings_paid!(lock_result[:earning_ids])
        withdrawal_log.update!(status: 'completed', paid_out_at: Time.current)
        { success: true, amount: amount }
      else
        release_earnings!(lock_result[:earning_ids])
        withdrawal_log.update!(status: 'failed', error_message: 'B2C disbursement failed')
        { success: false, error: 'Disbursement failed, please try again shortly' }
      end
    ensure
      Rails.cache.delete(cache_key)
    end
  end

  private

  # Locks available earnings, verifies the minimum, and reserves them
  # (status -> 'processing') INSIDE the transaction so a second
  # concurrent request sees zero available balance. The actual B2C
  # call happens *after* this transaction commits, so a slow Safaricom
  # response never holds the row lock open.
  def lock_and_reserve_balance
    result = { success: false }

    ActiveRecord::Base.transaction do
      earnings = ReferralEarning
                   .where(referrer: @referrer, status: 'available', paid_out: false)
                   .order(:created_at)
                   .lock!
                   .to_a

      balance = earnings.sum { |e| e.amount.to_f }

      if balance < MIN_WITHDRAWAL_AMOUNT
        result = {
          success: false,
          error: "Minimum withdrawal is KSh #{MIN_WITHDRAWAL_AMOUNT.to_i}. " \
                 "Available balance: KSh #{balance.to_i}"
        }
        raise ActiveRecord::Rollback
      end

      earnings.each { |e| e.update!(status: 'processing', paid_out: true) }

      withdrawal_log = ReferralWithdrawal.create!(
        referrer: @referrer,
        amount: balance,
        phone_number: @phone_number,
        idempotency_key: @idempotency_key,
        status: 'pending'
      )

      result = {
        success: true,
        amount: balance,
        earning_ids: earnings.map(&:id),
        withdrawal_log: withdrawal_log
      }
    end

    result
  end

  def mark_earnings_paid!(earning_ids)
    ReferralEarning.where(id: earning_ids).update_all(status: 'paid_out', paid_out_at: Time.current)
  end

  def release_earnings!(earning_ids)
    ReferralEarning.where(id: earning_ids).update_all(status: 'available', paid_out: false)
  end
end