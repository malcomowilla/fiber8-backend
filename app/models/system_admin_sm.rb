class SystemAdminSm < ApplicationRecord
  acts_as_tenant(:account)
end
