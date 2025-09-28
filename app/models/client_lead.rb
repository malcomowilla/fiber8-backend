class ClientLead < ApplicationRecord

  acts_as_tenant(:account)

   before_save :sanitize_fields

  private

  def sanitize_fields
    # Remove any HTML/JS tags from details before saving
    #  self.name = Sanitize.fragment(name)
  self.email = Sanitize.fragment(email)
  self.company_name = Sanitize.fragment(company_name)
  self.phone_number = Sanitize.fragment(phone_number)
  end
end
