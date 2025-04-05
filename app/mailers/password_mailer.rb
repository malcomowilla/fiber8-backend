class PasswordMailer < ApplicationMailer
  # default from: "malcomowilla@gmail.com"


  def reset(admin, reset_domain)

    @admin = admin

@reset_domain = reset_domain

  mail(
    from: tenant_sender_email,  # Replace with the actual sender email
    to: @admin.email,
    subject: 'Password Reset',
    category: 'Password Reset',
    
  )
  end






  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.password_mailer.reset.subject
  #
  # def reset
  #  @token =  params[:user].signed_id(purpose: "password_reset", expires_in: 30.minutes)


  #   mail to: params[:user].email
  # end


  # def edit
  #   @user = User.find_signed(params[:token], purpose:"password_reset" )
  # end
end
