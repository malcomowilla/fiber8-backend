class User < ApplicationRecord
    has_secure_password
    acts_as_tenant(:account)
    has_many :prefix_and_digits

    has_many :admin_web_authn_credentials, dependent: :destroy


    enum :role,  [:super_administrator, :technician,
 :customer_support,  :administrator, :agent]
 
#  validates :password, presence: true 

# validates :password_confirmation, confirmation: { case_sensitive: true}

# validate :validate_complex_password

# validates :email,  uniqueness: {case_sensitive: true}, format: { with: URI::MailTo::EMAIL_REGEXP } 
# # validate :validate_email_format
# validates :username, presence: true, length: {minimum: 6, maximum: 20}, uniqueness: true
# def validate_email_format
#     unless email.end_with?('@gmail.com') || email.end_with?('co.ke')
#         errors.add(:email, 'must be a valid email adress ending with gmail.com')
#     end
# end


# validates :password, presence: true, uniqueness: true
# validates :password, uniqueness: true, presence: true
# validate :validate_complex_password

   



def validate_complex_password
    if password.present? and !password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{12,}$/) 
        errors.add :password, "must include at least one lowercase letter, one uppercase letter, one digit,
         and needs to be minimum 12 characters."


      end
end
end
