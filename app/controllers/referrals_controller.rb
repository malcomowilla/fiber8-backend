class ReferralsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def my_code
    render json: {
      referral_code: @account.referral_code,
      signup_url: "https://owitech.co.ke/home?ref=#{@account.referral_code}"
    }
  end

  def my_referrals
    referrals = Account.where(referred_by_account_id: @account.id).order(created_at: :desc)

    render json: referrals.map { |r|
      earning = @account.referral_earnings.find_by(referred_account_id: r.id)
      {
        id: r.id,
        company_name: r.subdomain,
        signed_up_at: r.created_at,
        converted: r.referral_qualified_at.present?,
        reward_status: earning&.status || 'awaiting_subscription',
        reward_amount: earning&.amount
      }
    }
  end

  def my_earnings
    render json: {
      available_balance: @account.available_referral_balance,
      pending_balance: @account.pending_referral_balance,
      lifetime_earned: @account.referral_earnings.where.not(status: 'void').sum(:amount),
      history: @account.referral_earnings.order(created_at: :desc).map { |e|
        {
          id: e.id,
          amount: e.amount,
          status: e.status,
          referred_account: Account.find_by(id: e.referred_account_id)&.subdomain,
          created_at: e.created_at,
          available_at: e.available_at
        }
      }
    }
  end

  def withdraw
    idempotency_key = params[:idempotency_key].presence || request.headers['X-Idempotency-Key']

    result = ReferralWithdrawalService.call(
      referrer: @account,
      phone_number: params[:phone_number],
      idempotency_key: idempotency_key
    )

    if result[:success]
      render json: { success: true, withdrawn: result[:amount] }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def terms
    render json: { terms: ReferralTerms.inside_admin_terms }
  end
end