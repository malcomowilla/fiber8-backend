class EmailSetting < ApplicationRecord

  acts_as_tenant(:account)

end
