class OutsideReferrersController < ApplicationController
  before_action :authenticate_outside_referrer!, only: [:me, :dashboard, :withdraw]

  def sign_up
    referrer = OutsideReferrer.new(
      name: params[:name],
      email: params[:email],
      phone_number: params[:phone_number],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )

    if referrer.save
      issue_cookie(referrer)
      render json: { referral_code: referrer.referral_code }, status: :created
    else
      render json: { errors: referrer.errors }, status: :unprocessable_entity
    end
  end

  def sign_in
    referrer = OutsideReferrer.find_by(email: params[:email]) ||
               OutsideReferrer.find_by(phone_number: params[:phone_number])

    if referrer&.authenticate(params[:password])
      issue_cookie(referrer)
      render json: { referral_code: referrer.referral_code }, status: :ok
    else
      render json: { error: 'Invalid email/phone or password' }, status: :unauthorized
    end
  end

  def sign_out
    cookies.delete(:jwt_outside_referrer)
    head :no_content
  end

  def me
    render json: {
      name: @outside_referrer.name,
      email: @outside_referrer.email,
      phone_number: @outside_referrer.phone_number,
      referral_code: @outside_referrer.referral_code
    }
  end

  def dashboard
    referred = Account.where(referred_by_outside_referrer_id: @outside_referrer.id).order(created_at: :desc)

    render json: {
      referral_code: @outside_referrer.referral_code,
      signup_url: "https://owitech.co.ke/home?ref=#{@outside_referrer.referral_code}",
      available_balance: @outside_referrer.available_balance,
      pending_balance: @outside_referrer.pending_balance,
      lifetime_earned: @outside_referrer.lifetime_earned,
      referrals: referred.map { |r|
        earning = @outside_referrer.referral_earnings.find_by(referred_account_id: r.id)
        {
          id: r.id,
          company_name: r.subdomain,
          signed_up_at: r.created_at,
          converted: r.referral_qualified_at.present?,
          converted_at: r.referral_qualified_at,
          reward_status: earning&.status || 'awaiting_subscription',
          reward_amount: earning&.amount
        }
      },
      withdrawal_history: @outside_referrer.referral_withdrawals.order(created_at: :desc).map { |w|
        { id: w.id, amount: w.amount, status: w.status, created_at: w.created_at }
      }
    }
  end

  def withdraw
    idempotency_key = params[:idempotency_key].presence || request.headers['X-Idempotency-Key']

    result = ReferralWithdrawalService.call(
      referrer: @outside_referrer,
      phone_number: params[:phone_number] || @outside_referrer.phone_number,
      idempotency_key: idempotency_key
    )

    if result[:success]
      render json: { success: true, withdrawn: result[:amount] }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def terms
    render json: { terms: ReferralTerms.outside_referrer_terms }
  end

  private

  def issue_cookie(referrer)
    token = JWT.encode({ outside_referrer_id: referrer.id }, ENV['JWT_SECRET_KEY'], 'HS256')
    cookies.encrypted.signed[:jwt_outside_referrer] = { value: token, httponly: true, secure: true, sameSite: 'strict' }
  end

  def authenticate_outside_referrer!
    token = cookies.encrypted.signed[:jwt_outside_referrer]
    payload = JWT.decode(token, ENV['JWT_SECRET_KEY'], true, algorithm: 'HS256').first
    @outside_referrer = OutsideReferrer.find(payload['outside_referrer_id'])
  rescue
    render json: { error: 'Not authenticated' }, status: :unauthorized
  end
end