class SystemAdminSm < ApplicationRecord
  acts_as_tenant(:account)
  belongs_to :subscriber, optional: true

  
end
