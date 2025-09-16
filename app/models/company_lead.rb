class CompanyLead < ApplicationRecord

   before_save :sanitize_fields

  private

  def sanitize_fields
    # Remove any HTML/JS tags from details before saving
    self.details = Sanitize.fragment(details)
  end
end
