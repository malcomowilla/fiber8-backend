class SmsTemplate < ApplicationRecord

  acts_as_tenant(:account)

end
