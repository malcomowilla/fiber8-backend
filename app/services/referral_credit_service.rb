class ReferralCreditService
  # Applies as much of the account's available referral balance as possible
  # to their own unpaid license invoice. Same locking discipline as
  # ReferralWithdrawalService — earnings are locked and consumed inside one
  # transaction, so this can never be double-applied or race a withdrawal.
  def self.call(account:, invoice:)
    return { success: false, error: 'Invoice is already paid' } if invoice.status == 'paid'

    result = { success: false }

    ActiveRecord::Base.transaction do
      earnings = ReferralEarning
                   .where(referrer: account, status: 'available', paid_out: false)
                   .order(:created_at)
                   .lock!
                   .to_a

      available = earnings.sum { |e| e.amount.to_f }

      if available <= 0
        result = { success: false, error: 'No available referral credit to apply' }
        raise ActiveRecord::Rollback
      end

      due = invoice.total.to_f
      credit_to_apply = [available, due].min.round(2)

      consume_earnings!(earnings, credit_to_apply, account, invoice)

      new_total = (due - credit_to_apply).round(2)
      invoice.update!(
        total: new_total,
        credit_applied: invoice.credit_applied.to_f + credit_to_apply
      )

      if new_total <= 0
        invoice.update!(status: 'paid', amount_paid: due, total: 0)
        extend_license!(account)
      end

      result = {
        success: true,
        credit_applied: credit_to_apply,
        remaining_due: [new_total, 0].max,
        fully_paid: new_total <= 0
      }
    end

    result
  end

  def self.consume_earnings!(earnings, amount_to_consume, account, invoice)
    remaining = amount_to_consume

    earnings.each do |earning|
      break if remaining <= 0

      take = [earning.amount.to_f, remaining].min

      if take >= earning.amount.to_f
        # Whole earning consumed
        earning.update!(
          status: 'paid_out', paid_out: true, paid_out_at: Time.current,
          applied_to_invoice_id: invoice.id, applied_at: Time.current
        )
      else
       
        earning.update!(amount: (earning.amount.to_f - take).round(2))
        ReferralEarning.create!(
          referrer: account,
          referred_account_id: earning.referred_account_id,
          amount: take,
          status: 'paid_out',
          paid_out: true,
          paid_out_at: Time.current,
          reason: earning.reason,
          applied_to_invoice_id: invoice.id,
          applied_at: Time.current
        )
      end

      remaining -= take
    end
  end

  def self.extend_license!(account)
    plan = account.hotspot_and_dial_plan
    plan.update!(
      name: 'Hotspot And PPPOE Plan',
      expiry: (plan.expiry || Time.current) + 30.days,
      expiry_days: 30
    )
  end
end