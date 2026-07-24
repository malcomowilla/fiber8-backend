class DefaultSystemAdSetting < ApplicationRecord
 acts_as_tenant(:account)

end