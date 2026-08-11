# app/mailers/payment_gateway_otp_mailer.rb
class PaymentGatewayOtpMailer < ApplicationMailer
  def otp_code(user, code)
    @user = user
    @code = code
    @expiry_minutes = PaymentGatewayOtp::EXPIRY_MINUTES

    mail(
      to: user.email,
      subject: "#{@code} is your payment settings verification code"
    )
  end
end