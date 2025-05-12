class LicenseSetting < ApplicationRecord
  acts_as_tenant(:account)

end
