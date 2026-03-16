class AccessPoint < ApplicationRecord

  acts_as_tenant(:account)
end
