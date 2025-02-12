class AdminOnboardingMailer < ApplicationMailer
  

  # smtp_host, smtp_username, sender_email, smtp_password, api_key, domain
  def admin_onboarding(admin
   )
    @admin = admin
    # @domain = domain
    # @smtp_host = smtp_host
    # @smtp_username = smtp_username
    # @sender_email = sender_email
    # @smtp_password = smtp_password
    # @api_key = api_key
    # @company_name = company_name
    mail(
      from: 'info@aitechs.co.ke',  # Replace with the actual sender email
      to: @admin.email,
      subject: 'Welcome to Aitechs!',
      category: 'Admin Onboarding',
      
    )
  end
end

