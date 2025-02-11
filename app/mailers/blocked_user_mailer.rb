class BlockedUserMailer < ApplicationMailer
  # layout 'mailer'

  def notify_block(email)
    @email = email
    mail(to: 'malcomowilla@gmail.com',
    from: tenant_sender_email, 
    subject: "Account Blocked")
  end
end


