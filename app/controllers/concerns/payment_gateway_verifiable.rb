# app/controllers/concerns/payment_gateway_verifiable.rb
module PaymentGatewayVerifiable
  extend ActiveSupport::Concern

  SESSION_TTL_MINUTES = 15

  included do
    before_action :require_login_for_payment_gateway
    before_action :require_payment_gateway_verification
  end

  private

  def require_login_for_payment_gateway
    render json: { error: 'Please log in' }, status: :unauthorized unless current_user
  end

  def require_payment_gateway_verification
    account = Account.find_by(subdomain: request.headers['X-Subdomain'])
    return render json: { error: 'Invalid tenant' }, status: :not_found unless account

    setting = PaymentGatewayPinSetting.find_by(account_id: account.id)
    return if setting.nil? || setting.pin_digest.blank?

    verified_at_raw = session[:payment_gateway_verified_at]
    if verified_at_raw.blank?
      return render json: { error: 'PIN verification required', code: 'pin_required' }, status: :forbidden
    end

    verified_at = Time.zone.parse(verified_at_raw) rescue nil
    unless verified_at && verified_at > SESSION_TTL_MINUTES.minutes.ago
      session.delete(:payment_gateway_verified_at)
      return render json: { error: 'Session expired, please enter your PIN again', code: 'pin_expired' }, status: :forbidden
    end
  end
end