class AccessApplicationMailer < ApplicationMailer
  def verification_code(email, code)
    mail(to: email, subject: "Your verification code: #{code}") do |format|
      format.text do
        render plain: "Your Owitech verification code is #{code}.\n\n" \
                       "It expires in 10 minutes. If you didn't request this, ignore this email."
      end
    end
  end

  def rejected(application)
    mail(to: application.email, subject: 'Your Owitech application') do |format|
      format.text do
        render plain: "Hi #{application.name},\n\nWe couldn't approve your application for " \
                       "#{application.company_name} at this time.\n" \
                       "#{application.rejection_reason.present? ? "Reason: #{application.rejection_reason}\n" : ''}" \
                       "\nReply to this email if you'd like to discuss it."
      end
    end
  end
end