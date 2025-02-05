class SubscriberSetting < ApplicationRecord
  acts_as_tenant(:account)

end
