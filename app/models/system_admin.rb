class SystemAdmin < ApplicationRecord

  def generate_otp
    self.otp = rand(100000..999999).to_s
    # self.password = SecureRandom.base64(8)
    save!
end



def verify_otp(submitted_otp)
    self.otp == submitted_otp
  end
end

