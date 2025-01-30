
class AdminOtpMailer < ApplicationMailer
  default from: "info@aitechs.co.ke"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.password_mailer.reset.subject
  
  def admin_otp(admin)
      # from: 'info@aitechsent.net',
    @admin = admin  
   
    mail(
      to: @admin.email,
      subject: 'Your One Time Password'
    )
  end

  
end