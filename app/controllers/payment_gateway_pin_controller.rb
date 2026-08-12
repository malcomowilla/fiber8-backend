# app/controllers/payment_gateway_pin_controller.rb
class PaymentGatewayPinController < ApplicationController
  MAX_ATTEMPTS    = 5
  LOCKOUT_MINUTES = 5

  before_action :require_login
      set_current_tenant_through_filter

  before_action :set_tenant

  def require_login
    render json: { error: 'Please log in' }, status: :unauthorized unless current_user
  end

  # GET /api/payment_gateway_pin
  def show
    setting = PaymentGatewayPinSetting.find_by(account_id: @account.id)
    pin_set = setting.present? && setting.pin_digest.present?

    render json: {
      pin_set: pin_set,
      verified: pin_set ? session_still_valid? : true,
      session_ttl_minutes: PaymentGatewayVerifiable::SESSION_TTL_MINUTES,
      can_manage_pin: can?(:manage, :payment_gateway_pin)
    }
  end

  # POST /api/payment_gateway_pin/verify   { pin: "1234" }
  def verify
    if locked_out?
      return render json: { success: false, error: 'Too many attempts. Try again in a few minutes.', code: 'locked_out' },
        status: :too_many_requests
    end

    setting = PaymentGatewayPinSetting.find_by(account_id: @account.id)

    if setting.nil? || setting.pin_digest.blank?
      session[:payment_gateway_verified_at] = Time.current.iso8601
      return render json: { success: true }
    end

    if setting.authenticate_pin(params[:pin].to_s)
      session.delete(:payment_gateway_pin_attempts)
      session.delete(:payment_gateway_locked_until)
      session[:payment_gateway_verified_at] = Time.current.iso8601
      render json: { success: true }
    else
      register_failed_attempt
      render json: { success: false, error: 'Incorrect PIN' }, status: :unauthorized
    end
  end

  # PATCH /api/payment_gateway_pin
  def update
    unless can?(:manage, :payment_gateway_pin)
      return render json: { error: 'Only an authorized admin can set or change the payment settings PIN' },
        status: :forbidden
    end

    setting = PaymentGatewayPinSetting.find_or_initialize_by(account_id: @account.id)
    new_pin = params[:new_pin].to_s
    confirmation = params[:new_pin_confirmation].to_s

    unless new_pin =~ /\A\d{4,6}\z/
      return render json: { error: 'PIN must be 4 to 6 digits' }, status: :unprocessable_entity
    end

    if new_pin != confirmation
      return render json: { error: "PINs don't match" }, status: :unprocessable_entity
    end

    if setting.persisted? && setting.pin_digest.present?
      unless setting.authenticate_pin(params[:current_pin].to_s)
        return render json: { error: 'Current PIN is incorrect' }, status: :unauthorized
      end
    end

    setting.pin = new_pin

    if setting.save
      session[:payment_gateway_verified_at] = Time.current.iso8601
      ActivtyLog.create(action: 'configuration', ip: request.remote_ip,
        description: 'Updated payment settings PIN', user_agent: request.user_agent,
        user: current_user.username || current_user.email, date: Time.current)
      render json: { success: true, pin_set: true }
    else
      render json: { error: setting.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  # DELETE /api/payment_gateway_pin   { current_pin: "1234" }
  def destroy
    unless can?(:manage, :payment_gateway_pin)
      return render json: { error: 'Only an authorized admin can remove PIN protection' },
        status: :forbidden
    end

    setting = PaymentGatewayPinSetting.find_by(account_id: @account.id)
    return render json: { success: true, pin_set: false } if setting.nil? || setting.pin_digest.blank?

    unless setting.authenticate_pin(params[:current_pin].to_s)
      return render json: { error: 'Current PIN is incorrect' }, status: :unauthorized
    end

    setting.destroy
    session.delete(:payment_gateway_verified_at)

    ActivtyLog.create(action: 'configuration', ip: request.remote_ip,
      description: 'Removed payment settings PIN protection', user_agent: request.user_agent,
      user: current_user.username || current_user.email, date: Time.current)

    render json: { success: true, pin_set: false }
  end

  private

  def set_tenant
    @account = Account.find_by(subdomain: request.headers['X-Subdomain'])
    render json: { error: 'Invalid tenant' }, status: :not_found unless @account
  end

  def session_still_valid?
    verified_at_raw = session[:payment_gateway_verified_at]
    return false if verified_at_raw.blank?
    verified_at = Time.zone.parse(verified_at_raw) rescue nil
    verified_at && verified_at > PaymentGatewayVerifiable::SESSION_TTL_MINUTES.minutes.ago
  end

  def locked_out?
    locked_until_raw = session[:payment_gateway_locked_until]
    return false if locked_until_raw.blank?
    locked_until = Time.zone.parse(locked_until_raw) rescue nil
    locked_until && locked_until > Time.current
  end

  def register_failed_attempt
    attempts = session[:payment_gateway_pin_attempts].to_i + 1
    session[:payment_gateway_pin_attempts] = attempts
    if attempts >= MAX_ATTEMPTS
      session[:payment_gateway_locked_until] = (Time.current + LOCKOUT_MINUTES.minutes).iso8601
      session[:payment_gateway_pin_attempts] = 0
    end
  end
end