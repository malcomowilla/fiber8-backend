class RouterSetting < ApplicationRecord
  acts_as_tenant(:account)
end



