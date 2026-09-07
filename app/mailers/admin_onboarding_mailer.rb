class AdminOnboardingMailer < ApplicationMailer
  def admin_onboarding(admin, password, login_url)
    @admin = admin
    @password = password
    @login_url = login_url

    mail(
      from: 'support@owitech.co.ke',
      to: @admin.email,
      subject: 'Welcome to Owitech ISP!',
      category: 'Admin Onboarding'
    )
  end
end