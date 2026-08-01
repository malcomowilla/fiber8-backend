class CompanyLead < ApplicationRecord

   before_save :sanitize_fields

   SOURCES = %w[manual website_linger referral import].freeze
validates :source, inclusion: { in: SOURCES }, allow_blank: true



STATUSES = %w[new contacted qualified converted lost].freeze

enum status: {
  new_lead:  'new',
  contacted: 'contacted',
  qualified: 'qualified',
  converted: 'converted',
  lost:      'lost'
}, _default: 'new'
  private

  def sanitize_fields
    # Remove any HTML/JS tags from details before saving
    # self.name = Sanitize.fragment(name)
  self.name = Sanitize.fragment(name)
  self.email = Sanitize.fragment(email)
  self.company_name = Sanitize.fragment(company_name)
  self.message = Sanitize.fragment(message)
  self.phone_number = Sanitize.fragment(phone_number)

  end
end
