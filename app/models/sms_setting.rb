class SmsSetting < ApplicationRecord
  acts_as_tenant(:account)

end
