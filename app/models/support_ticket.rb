class SupportTicket < ApplicationRecord
  auto_increment :sequence_number
  acts_as_tenant(:account)
end
