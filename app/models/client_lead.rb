class ClientLead < ApplicationRecord

  acts_as_tenant(:account)
end
