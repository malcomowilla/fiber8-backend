class AccessApplicationMailer < ApplicationMailer
  SENDER = 'support@owitech.co.ke'.freeze

  def verification_code(email, code)
    @code = code

    mail(
      from: SENDER,
      to: email,
      subject: "Your Owitech verification code: #{code}",
      category: 'Application Verification'
    )
  end

  def rejected(application)
    @application = application

    mail(
      from: SENDER,
      to: application.email,
      subject: 'Your Owitech application',
      category: 'Application Rejected'
    )
  end
end