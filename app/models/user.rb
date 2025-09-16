class User < ApplicationRecord
    has_secure_password(validations: false)

    acts_as_tenant(:account)
    has_many :prefix_and_digits
    has_one :admin_setting, dependent: :destroy
    # has_one :sms_setting, dependent: :destroy
    has_many :admin_web_authn_credentials, dependent: :destroy




   before_save :sanitize_fields


  def sanitize_fields
    # Remove any HTML/JS tags from details before saving
    #  self.name = Sanitize.fragment(name)
  self.email = Sanitize.fragment(email)
  self.message = Sanitize.fragment(message)
  self.phone_number = Sanitize.fragment(phone_number)
  self.username = Sanitize.fragment(username)
  end
    # before_destroy :delete_admin_setting

#     enum :role,  [:super_administrator, :technician,
#  :customer_support,  :administrator, :agent]
 
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

# def verify_totp(code)
#     return false unless  self.otp_secret.present?
    
#     totp = ROTP::TOTP.new(otp_secret)
#     totp.verify(code, drift_behind: 15, drift_ahead: 15)
#   end
  
#   def verify_backup_code(code)
#     return false unless self.otp_backup_codes.present?
    
#     otp_backup_codes.include?(code) && 
#       (otp_backup_codes.delete(code) && save!)
#   end

private

def delete_admin_setting
    admin_setting.destroy if admin_setting.present?
  end

def validate_complex_password
    if password.present? and !password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{12,}$/) 
        errors.add :password, "must include at least one lowercase letter, one uppercase letter, one digit,
         and needs to be minimum 12 characters."


      end
end
end
