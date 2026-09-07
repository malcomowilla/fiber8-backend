class AdminOnboardingMailer < ApplicationMailer
  

  # smtp_host, smtp_username, sender_email, smtp_password, api_key, domain
  def admin_onboarding(admin, password, subdomain
   )
    @admin = admin
   
    mail(
      from: 'support@owitech.co.ke',  # Replace with the actual sender email
      to: @admin.email,
      subject: 'Welcome to Owitech ISP!',
      category: 'Admin Onboarding',
      
    )
  end
end

