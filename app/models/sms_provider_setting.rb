class SmsProviderSetting < ApplicationRecord

  acts_as_tenant(:account)


end
