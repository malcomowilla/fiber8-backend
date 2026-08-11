# app/controllers/concerns/payment_gateway_verifiable.rb
#
# Include this in any controller that reads or writes payment gateway
# credentials (M-Pesa, Tuma, etc). Blocks every action in the controller
# behind a fresh OTP check unless explicitly skipped.
#
# The verification flag lives in the Rails session itself (not the DB),
# so it's automatically scoped per browser session and disappears on
# logout / new session — satisfying "re-verify every session" without
# extra bookkeeping. It also expires after SESSION_TTL_MINUTES of
# inactivity as a defense-in-depth measure (e.g. an unlocked, unattended
# browser tab).
#
# Usage in a controller that should be fully gated:
#
#   class TumaSettingsController < ApplicationController
#     include PaymentGatewayVerifiable
#     # ... existing before_actions/actions ...
#   end
#
# Usage where one action must stay open (e.g. a payment webhook):
#
#   class HotspotMpesaSettingsController < ApplicationController
#     include PaymentGatewayVerifiable
#     skip_before_action :require_payment_gateway_verification,
#       only: [:customer_mpesa_stk_payments]
#   end
module PaymentGatewayVerifiable
  extend ActiveSupport::Concern

  SESSION_TTL_MINUTES = 15

  included do
    before_action :require_payment_gateway_verification
  end

  private

  def require_payment_gateway_verification
    verified_at_raw = session[:payment_gateway_verified_at]

    if verified_at_raw.blank?
      return render json: { error: 'Verification required', code: 'otp_required' }, status: :forbidden
    end

    verified_at = Time.zone.parse(verified_at_raw) rescue nil

    unless verified_at && verified_at > SESSION_TTL_MINUTES.minutes.ago
      session.delete(:payment_gateway_verified_at)
      return render json: { error: 'Verification expired, please re-verify', code: 'otp_expired' }, status: :forbidden
    end
  end
end