# app/controllers/payment_gateway_otp_controller.rb
#
# Powers the 2FA gate in front of M-Pesa / Tuma settings pages.
# NOT included in PaymentGatewayVerifiable itself — this controller is
# how the user *gets* verified in the first place, so it can't require
# verification to run.
class PaymentGatewayOtpController < ApplicationController
  set_current_tenant_through_filter

  before_action :set_tenant

  SESSION_TTL_MINUTES = PaymentGatewayVerifiable::SESSION_TTL_MINUTES

  # GET /api/payment_gateway_otp/status
  def status
    verified_at_raw = session[:payment_gateway_verified_at]
    verified_at = verified_at_raw.present? ? (Time.zone.parse(verified_at_raw) rescue nil) : nil
    verified = verified_at.present? && verified_at > SESSION_TTL_MINUTES.minutes.ago

    render json: {
      verified: verified,
      expires_in_seconds: verified ? ((verified_at + SESSION_TTL_MINUTES.minutes) - Time.current).to_i : 0
    }
  end

  # POST /api/payment_gateway_otp/request  { channel: 'sms' | 'email' }
  def request_otp
    channel = params[:channel].to_s

    unless %w[sms email].include?(channel)
      return render json: { error: 'channel must be sms or email' }, status: :unprocessable_entity
    end

    if channel == 'sms' && current_user.phone_number.blank?
      return render json: { error: 'No phone number on file for SMS. Try email instead.' }, status: :unprocessable_entity
    end

    if channel == 'email' && current_user.email.blank?
      return render json: { error: 'No email on file. Try SMS instead.' }, status: :unprocessable_entity
    end

    if PaymentGatewayOtp.rate_limited?(current_user)
      return render json: { error: 'Too many codes requested. Please wait a few minutes and try again.' },
        status: :too_many_requests
    end

    otp, code = PaymentGatewayOtp.generate_for(
      user: current_user, account: @account, channel: channel, request_ip: request.remote_ip
    )

    if channel == 'sms'
      deliver_sms(current_user, code)
      destination = mask_phone(current_user.phone_number)
    else
      PaymentGatewayOtpMailer.otp_code(current_user, code).deliver_later
      destination = mask_email(current_user.email)
    end

    render json: {
      message: "Verification code sent via #{channel}",
      destination: destination,
      expires_in_seconds: PaymentGatewayOtp::EXPIRY_MINUTES * 60
    }
  rescue => e
    Rails.logger.error "PaymentGatewayOtp request_otp failed: #{e.class} #{e.message}"
    render json: { error: 'Could not send verification code. Please try again.' }, status: :internal_server_error
  end

  # POST /api/payment_gateway_otp/verify  { code: '123456' }
  def verify
    otp = PaymentGatewayOtp.where(user_id: current_user.id, consumed_at: nil)
                            .order(created_at: :desc).first

    unless otp
      return render json: { error: 'No pending code. Please request a new one.' }, status: :unprocessable_entity
    end

    case otp.verify(params[:code].to_s)
    when :ok
      session[:payment_gateway_verified_at] = Time.current.iso8601
      ActivtyLog.create(action: 'security', ip: request.remote_ip,
        description: "Verified 2FA for payment gateway settings access (#{otp.channel})",
        user_agent: request.user_agent, user: current_user.username || current_user.email,
        date: Time.current)
      render json: { verified: true, expires_in_seconds: SESSION_TTL_MINUTES * 60 }
    when :expired
      render json: { error: 'Code expired. Please request a new one.' }, status: :unprocessable_entity
    when :locked
      render json: { error: 'Too many incorrect attempts. Please request a new code.' }, status: :unprocessable_entity
    when :already_used
      render json: { error: 'Code already used. Please request a new one.' }, status: :unprocessable_entity
    else
      render json: { error: 'Incorrect code. Please try again.' }, status: :unprocessable_entity
    end
  end

  private

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # NOTE: adjust the class/method name below to match whatever your
  # existing SmslLeopard wrapper is actually called elsewhere in the app
  # (used already for support-ticket SMS notifications) — this is a
  # best-guess call shape, not copied from a file I've seen.
  def deliver_sms(user, code)
    message = "Your Owitech payment settings verification code is #{code}. " \
              "It expires in #{PaymentGatewayOtp::EXPIRY_MINUTES} minutes. Do not share this code with anyone."
    SmsLeopardService.new.send_sms(phone: user.phone_number, message: message)
  end

  def mask_phone(phone)
    return nil if phone.blank?
    "#{phone[0..3]}****#{phone[-2..]}"
  end

  def mask_email(email)
    return nil if email.blank?
    name, domain = email.split('@')
    "#{name[0..1]}***@#{domain}"
  end
end