class PasswordMailer < ApplicationMailer
  default from: "malcomowilla@gmail.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.password_mailer.reset.subject
  #
  def reset
   @token =  params[:user].signed_id(purpose: "password_reset", expires_in: 30.minutes)


    mail to: params[:user].email
  end


  def edit
    @user = User.find_signed(params[:token], purpose:"password_reset" )
  end
end
