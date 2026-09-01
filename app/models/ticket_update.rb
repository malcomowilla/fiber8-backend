class TicketUpdate < ApplicationRecord
  belongs_to :support_ticket
  validates :status, presence: true
   acts_as_tenant(:account)
end