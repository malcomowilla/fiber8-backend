
class SuperAdminInvitationMailer < ApplicationMailer
  def super_admins(admin, invitation_link, company_name, company_photo)
    @admin = admin
    @company_name = company_name
    @company_photo = company_photo
    @invitation_link = invitation_link
    mail(to: @admin.email, subject: "Welcome to #{@company_name}",
    from: tenant_sender_email,  
    )
  end
end



