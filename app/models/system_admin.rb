class SystemAdmin < ApplicationRecord
  has_secure_password
  has_many :system_admin_web_authn_credentials, dependent: :destroy
  has_one :system_admin_setting, dependent: :destroy

  def generate_otp
    self.otp = rand(100000..999999).to_s
    # self.password = SecureRandom.base64(8)
    save!
end



def verify_otp(submitted_otp)
    self.otp == submitted_otp
  end


end

