class Technician < ApplicationRecord

   has_secure_password(validations: false)
    acts_as_tenant(:account)


   before_save :sanitize_fields


  def sanitize_fields
    # Remove any HTML/JS tags from details before saving
    #  self.name = Sanitize.fragment(name)
  self.email = Sanitize.fragment(email)
  self.phone_number = Sanitize.fragment(phone_number)
  self.username = Sanitize.fragment(username)
  end

end
